package auth;

import org.pac4j.core.util.CommonHelper;
import org.pac4j.play.store.DataEncrypter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;

public class AesDataEncrypter implements DataEncrypter {
    protected final Logger logger = LoggerFactory.getLogger(this.getClass());
    private final byte[] key;
    private final IvParameterSpec iv;
    private final SecretKeySpec skeySpec;
    private final String transformation = "AES/CBC/PKCS5PADDING";

    public AesDataEncrypter(byte[] key) {
        CommonHelper.assertNotNull("key", key);
        this.key = key.clone();
        iv = new IvParameterSpec(this.key);
        skeySpec = new SecretKeySpec(this.key, "AES");
    }

    public AesDataEncrypter() {
        SecureRandom random = new SecureRandom();
        byte[] bytes = new byte[16];
        random.nextBytes(bytes);
        this.key = bytes;
        iv = new IvParameterSpec(this.key);
        skeySpec = new SecretKeySpec(this.key, "AES");
    }

    public byte[] encrypt(byte[] rawBytes) {
        try {
            Cipher cipher = Cipher.getInstance(transformation);
            cipher.init(Cipher.ENCRYPT_MODE, skeySpec, iv);
            return cipher.doFinal(rawBytes);
        } catch (Exception ex) {
            logger.error("error while encrypting: ", ex);
        }
        return null;
    }

    public byte[] decrypt(byte[] encryptedBytes) {
        try {
            Cipher cipher = Cipher.getInstance(transformation);
            cipher.init(Cipher.DECRYPT_MODE, skeySpec, iv);
            return cipher.doFinal(encryptedBytes);
        } catch (Exception ex) {
            logger.error("error while decrypting: ", ex);
        }
        return null;
    }
}
