<?php
/**
 * Local security fix (Empires of Rome): rate limits for logins and password
 * reset requests.
 *
 * Each failed login / reset request is one row (kind, sha256 of the IP or
 * account, time). Only hashes are stored, never plain IPs or names, and
 * prune() (AutomationCleanup) drops rows after a day.
 */
class AuthThrottle
{
    /** Failed logins allowed per IP / per account inside LOGIN_WINDOW. */
    const LOGIN_IP_MAX   = 20;
    const LOGIN_USER_MAX = 8;
    const LOGIN_WINDOW   = 900;

    /** Reset e-mails allowed per IP / per account inside RESET_WINDOW. */
    const RESET_IP_MAX   = 5;
    const RESET_USER_MAX = 3;
    const RESET_WINDOW   = 3600;

    private static $ready = false;

    private static function link()
    {
        global $database;
        return $database->dblink;
    }

    private static function ensureTable()
    {
        if (self::$ready) return;
        mysqli_query(self::link(), "CREATE TABLE IF NOT EXISTS `" . TB_PREFIX . "tz_auth_throttle` (
            `id`   int(11)     NOT NULL AUTO_INCREMENT,
            `kind` varchar(16) NOT NULL,
            `k`    char(64)    NOT NULL,
            `time` int(11)     NOT NULL,
            PRIMARY KEY (`id`),
            KEY `kind_k_time` (`kind`, `k`, `time`),
            KEY `time` (`time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        self::$ready = true;
    }

    /** The visitor's IP (Cloudflare-aware, see IpResolver). */
    public static function ip()
    {
        return \App\Utils\IpResolver::getClientIp() ?? ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
    }

    private static function key($value)
    {
        return hash('sha256', strtolower(trim((string) $value)));
    }

    private static function kind($kind)
    {
        return preg_replace('/[^a-z_]/', '', (string) $kind);
    }

    /** Number of hits for ($kind, $value) in the last $window seconds. */
    public static function count($kind, $value, $window)
    {
        self::ensureTable();
        $r = mysqli_query(self::link(), "SELECT COUNT(*) FROM `" . TB_PREFIX . "tz_auth_throttle`
            WHERE kind = '" . self::kind($kind) . "' AND k = '" . self::key($value) . "' AND `time` > " . (time() - (int) $window));
        $row = $r ? mysqli_fetch_row($r) : null;
        return $row ? (int) $row[0] : 0;
    }

    public static function hit($kind, $value)
    {
        self::ensureTable();
        mysqli_query(self::link(), "INSERT INTO `" . TB_PREFIX . "tz_auth_throttle` (kind, k, `time`)
            VALUES ('" . self::kind($kind) . "', '" . self::key($value) . "', " . time() . ")");
    }

    public static function clear($kind, $value)
    {
        self::ensureTable();
        mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_auth_throttle`
            WHERE kind = '" . self::kind($kind) . "' AND k = '" . self::key($value) . "'");
    }

    /** True while this IP or account has too many failed logins. */
    public static function loginBlocked($username)
    {
        return self::count('login_ip', self::ip(), self::LOGIN_WINDOW) >= self::LOGIN_IP_MAX
            || ($username !== '' && self::count('login_user', $username, self::LOGIN_WINDOW) >= self::LOGIN_USER_MAX);
    }

    public static function loginFailed($username)
    {
        self::hit('login_ip', self::ip());
        if ($username !== '') self::hit('login_user', $username);
    }

    /** Drops rows older than a day; returns how many went. */
    public static function prune()
    {
        self::ensureTable();
        mysqli_query(self::link(), "DELETE FROM `" . TB_PREFIX . "tz_auth_throttle` WHERE `time` < " . (time() - 86400));
        return mysqli_affected_rows(self::link());
    }
}
