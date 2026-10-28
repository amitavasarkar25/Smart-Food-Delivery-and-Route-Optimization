
package com.smartfood;

import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class PasswordUtil {

    private static final int ITERATIONS = 210000;
    private static final int SALT_LENGTH = 16;
    private static final int HASH_LENGTH = 32;

    private static final SecureRandom RANDOM = new SecureRandom();

    // Hash a new password before storing it in the database.
    public static String hashPassword(String password) {

        if (password == null || password.isEmpty()) {
            throw new IllegalArgumentException(
                    "Password cannot be empty.");
        }

        byte[] salt = new byte[SALT_LENGTH];
        RANDOM.nextBytes(salt);

        byte[] hash = generateHash(
                password.toCharArray(),
                salt,
                ITERATIONS,
                HASH_LENGTH
        );

        return "pbkdf2$" + ITERATIONS + "$"
                + Base64.getEncoder().encodeToString(salt) + "$"
                + Base64.getEncoder().encodeToString(hash);
    }

    // Verify a password against the stored database hash.
    public static boolean verifyPassword(
            String enteredPassword, String storedPassword) {

        if (enteredPassword == null || storedPassword == null) {
            return false;
        }

        try {
            String[] parts = storedPassword.split("\\$");

            // Format: pbkdf2$iterations$salt$hash
            if (parts.length != 4 || !parts[0].equals("pbkdf2")) {
                return false;
            }

            int iterations = Integer.parseInt(parts[1]);

            // Reject unreasonable or invalid stored parameters.
            if (iterations < 1 || iterations > 1000000) {
                return false;
            }

            byte[] salt = Base64.getDecoder().decode(parts[2]);
            byte[] expectedHash = Base64.getDecoder().decode(parts[3]);

            if (salt.length < 16 || expectedHash.length != HASH_LENGTH) {
                return false;
            }

            byte[] actualHash = generateHash(
                    enteredPassword.toCharArray(),
                    salt,
                    iterations,
                    expectedHash.length
            );

            return java.security.MessageDigest.isEqual(
                    expectedHash, actualHash);

        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private static byte[] generateHash(
            char[] password,
            byte[] salt,
            int iterations,
            int hashLength) {

        PBEKeySpec spec = new PBEKeySpec(
                password, salt, iterations, hashLength * 8);

        try {
            SecretKeyFactory factory =
                    SecretKeyFactory.getInstance(
                            "PBKDF2WithHmacSHA256");

            return factory.generateSecret(spec).getEncoded();

        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(
                    "Unable to generate password hash.", e);

        } finally {
            spec.clearPassword();
            java.util.Arrays.fill(password, '\0');
        }
    }
}
