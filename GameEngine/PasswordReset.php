<?php
/**
 * Local security fix (Empires of Rome): password reset by one-time link.
 *
 * Replaces the old flow that e-mailed a generated password in plain text and
 * kept it unhashed in the `password` table until confirmed. Now the e-mail
 * holds a random 256-bit token; only its sha256 is stored (tz_pwreset), it
 * expires after TTL seconds, works once, and only the newest link per account
 * is valid. Setting the new password changes the password hash, which ends
 * every existing session of the account (see Session::checkLogin).
 */
class PasswordReset
{
    const TTL = 3600;

    private static $ready = false;

    private static function link()
    {
        global $database;
        return $database->dblink;
    }

    private static function ensureTable()
    {
        if (self::$ready) return;
        mysqli_query(self::link(), "CREATE TABLE IF NOT EXISTS `" . TB_PREFIX . "tz_pwreset` (
            `id`         int(11)  NOT NULL AUTO_INCREMENT,
            `uid`        int(11)  NOT NULL,
            `token_hash` char(64) NOT NULL,
            `created`    int(11)  NOT NULL,
            `expires`    int(11)  NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `token_hash` (`token_hash`),
            KEY `uid` (`uid`),
            KEY `expires` (`expires`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        self::$ready = true;
    }

    /**
     * Sends a reset link to every account (max 3) registered with $email.
     * Says nothing back: the page shows the same text whether or not the
     * address exists, and requests over the rate limits are dropped silently.
     */
    public static function request($email)
    {
        global $mailer;

        $email = trim((string) $email);
        if ($email === '' || strlen($email) > 100) return;

        $ip = AuthThrottle::ip();
        if (AuthThrottle::count('reset_ip', $ip, AuthThrottle::RESET_WINDOW) >= AuthThrottle::RESET_IP_MAX) return;
        AuthThrottle::hit('reset_ip', $ip);

        self::ensureTable();
        $e = mysqli_real_escape_string(self::link(), $email);
        // ids 1-5 are the system accounts (Support, Nature, Natars, Taskmaster, Multihunter)
        $r = mysqli_query(self::link(), "SELECT id, username, email FROM `" . TB_PREFIX . "users`
            WHERE email = '$e' AND id > 5 LIMIT 3");

        while ($r && ($u = mysqli_fetch_assoc($r))) {
            $uid = (int) $u['id'];
            if (AuthThrottle::count('reset_user', $uid, AuthThrottle::RESET_WINDOW) >= AuthThrottle::RESET_USER_MAX) continue;
            AuthThrottle::hit('reset_user', $uid);

            $token = bin2hex(random_bytes(32));
            mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_pwreset` WHERE uid = $uid");
            mysqli_query(self::link(), "INSERT INTO `" . TB_PREFIX . "tz_pwreset` (uid, token_hash, created, expires)
                VALUES ($uid, '" . hash('sha256', $token) . "', " . time() . ", " . (time() + self::TTL) . ")");

            $mailer->sendPasswordReset($u['email'], $u['username'], SERVER . 'password.php?token=' . $token);
        }
    }

    /** Account id for a valid, unexpired token; 0 otherwise. */
    public static function check($token)
    {
        if (!is_string($token) || !preg_match('/^[a-f0-9]{64}$/', $token)) return 0;

        self::ensureTable();
        $r = mysqli_query(self::link(), "SELECT uid FROM `" . TB_PREFIX . "tz_pwreset`
            WHERE token_hash = '" . hash('sha256', $token) . "' AND expires > " . time() . " LIMIT 1");
        $row = $r ? mysqli_fetch_assoc($r) : null;
        return $row ? (int) $row['uid'] : 0;
    }

    /**
     * Sets the new password for the token's account. Returns '' on success,
     * 'invalid' for a bad/expired token, or a message to show next to the form.
     */
    public static function complete($token, $pw1, $pw2)
    {
        global $database;

        $uid = self::check($token);
        if (!$uid) return 'invalid';

        $pw1 = (string) $pw1;
        $min = defined('PW_MIN_LENGTH') ? (int) PW_MIN_LENGTH : 4;
        if (strlen($pw1) < $min) return 'The password must be at least ' . $min . ' characters long.';
        if (strlen($pw1) > 100) return 'The password can be at most 100 characters long.';
        if ($pw1 !== (string) $pw2) return 'The two passwords do not match.';

        $username = (string) $database->getUserField($uid, 'username', 0);
        if ($username !== '' && strcasecmp($pw1, $username) === 0) return 'The password must not be the same as your account name.';

        $database->updateUserField($uid, 'password', password_hash($pw1, PASSWORD_BCRYPT, ['cost' => 12]), 1);
        mysqli_query(self::link(), "UPDATE `" . TB_PREFIX . "users` SET sessid = '' WHERE id = $uid");
        mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_pwreset` WHERE uid = $uid");
        AuthThrottle::clear('login_user', $username);

        return '';
    }

    /** Removes expired links; returns how many went. */
    public static function prune()
    {
        self::ensureTable();
        mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_pwreset` WHERE expires < " . time());
        return mysqli_affected_rows(self::link());
    }

    /** Drops every link of an account (account deletion). */
    public static function forget($uid)
    {
        self::ensureTable();
        mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_pwreset` WHERE uid = " . (int) $uid);
    }
}
