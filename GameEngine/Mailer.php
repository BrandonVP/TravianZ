<?php

#################################################################################
##              -= YOU MAY NOT REMOVE OR CHANGE THIS NOTICE =-                 ##
## --------------------------------------------------------------------------- ##
##  Filename       : Mailer.php                      	                       ##
##  Type           : Mailer System Backend                                     ##
## --------------------------------------------------------------------------- ##
##  Developed by   : Dixie           			                               ##
##  Refactored by  : Shadow & Ferywir									       ##
##  Thanks to      : ronix, InCube, Akakori, Elmar & Kirilloid                 ##
## --------------------------------------------------------------------------- ##
##  Contact        : cata7007@gmail.com                                        ##
##  Project        : TravianZ                                                  ##
##  URLs:          : https://travianz.org                                      ##
##  GitHub         : https://github.com/Shadowss/TravianZ                      ##
## --------------------------------------------------------------------------- ##
##  License        : TravianZ Project                                          ##
##  Copyright      : TravianZ (c) 2010-2026. All rights reserved.              ##
## --------------------------------------------------------------------------- ##
#################################################################################

class Mailer
{
	/**
	 * -------------------------------------------------------------------------
	 * SEND ACTIVATION EMAIL
	 * -------------------------------------------------------------------------
	 */
	function sendActivate($email, $username, $pass, $act)
	{
		$subject = "Welcome to " . SERVER_NAME;

		$message =
			"Hello " . $username . "\n\n" .
			"Thank you for your registration.\n\n" .
			"----------------------------\n" .
			"Name: " . $username . "\n" .
			"Activation code: " . $act . "\n" .   // local security fix: no password in e-mails
			"----------------------------\n\n" .
			"Click the following link in order to activate your account:\n" .
			SERVER . "activate.php?code=" . $act . "\n\n" .
			"Greetings,\n" .
			SERVER_NAME . " team";

		$headers = "From: " . ADMIN_EMAIL . "\r\n";

		@mail($email, $subject, $message, $headers);
	}

	/**
	 * -------------------------------------------------------------------------
	 * SEND INVITE EMAIL
	 * -------------------------------------------------------------------------
	 * FIX: $username was undefined -> fallback safe value added
	 */
	function sendInvite($email, $uid, $text){
		
	$email = trim($email);
	$uid = (int)$uid;
	$text = trim($text);

	// Protecție împotriva Email Header Injection
	if (
		strpos($email, "\r") !== false ||
		strpos($email, "\n") !== false ||
		!filter_var($email, FILTER_VALIDATE_EMAIL)
	) {
		return false;
	}

	// Curățăm textul
	$text = substr($text, 0, 2000);
	$text = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/', '', $text);

	$subject = SERVER_NAME . " registration";

	$username = "User";

	$message =
		"Hello " . $username . "\n\n" .
		"Try the new " . SERVER_NAME . "!\n\n\n" .
		"Link: " . SERVER . "anmelden.php?id=ref" . $uid . "\n\n" .
		$text . "\n\n\n" .
		"Greetings,\n" .
		SERVER_NAME . " team";

	$headers = "From: " . ADMIN_EMAIL . "\r\n";

	return @mail($email, $subject, $message, $headers);
	}

	/**
	 * -------------------------------------------------------------------------
	 * SEND PASSWORD RESET LINK (local security fix)
	 * -------------------------------------------------------------------------
	 * The old sendPassword() mailed a new plain-text password and built its
	 * link from the Host header. The link now comes from PasswordReset with
	 * SERVER as base.
	 */
	function sendPasswordReset($email, $username, $link)
	{
		if (strpos($email, "\r") !== false || strpos($email, "\n") !== false || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
			return false;
		}

		$subject = SERVER_NAME . " - reset your password";

		$message =
			"Hello " . $username . "\n\n" .
			"Someone (hopefully you) asked to reset the password of your " . SERVER_NAME . " account.\n\n" .
			"Open this link within one hour to choose a new password:\n" .
			$link . "\n\n" .
			"The link works once. If you did not ask for this, ignore this e-mail - your password stays the same.\n\n" .
			SERVER_NAME . " team";

		$headers = "From: " . ADMIN_EMAIL . "\r\n";

		return @mail($email, $subject, $message, $headers);
	}
}

/**
 * -------------------------------------------------------------------------
 * GLOBAL INSTANCE (legacy compatibility)
 * -------------------------------------------------------------------------
 */
$mailer = new Mailer();

?>