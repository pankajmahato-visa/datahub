package auth;

import org.pac4j.core.context.session.SessionStore;
import org.pac4j.core.profile.CommonProfile;
import org.pac4j.core.util.JavaSerializationHelper;
import org.pac4j.play.PlayWebContext;
import org.pac4j.play.store.DataEncrypter;
import org.pac4j.play.store.PlaySessionStore;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import play.mvc.Http;

import javax.inject.Singleton;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.Serializable;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Optional;
import java.util.zip.GZIPInputStream;
import java.util.zip.GZIPOutputStream;

@Singleton
public class PlayCookieSessionStore implements PlaySessionStore {
    private static final Logger logger = LoggerFactory.getLogger(org.pac4j.play.store.PlayCookieSessionStore.class);
//    private final String tokenName = "pac4j";
//    private final String keyPrefix = "pac4j_";
    private final DataEncrypter dataEncrypter;
    public static final JavaSerializationHelper JAVA_SER_HELPER = new JavaSerializationHelper();

    public PlayCookieSessionStore(DataEncrypter dataEncrypter) {
        this.dataEncrypter = dataEncrypter;
    }

    public String getOrCreateSessionId(PlayWebContext context) {
        return "pac4j";
    }

    public Optional<Object> get(PlayWebContext context, String key) {
        Http.Session session = context.getNativeSession();
        String sessionValue = session.get("pac4j_" + key).orElse(null);
        if (sessionValue == null) {
            logger.trace("get, key = {} -> null", key);
            return Optional.empty();
        } else {
            byte[] inputBytes = Base64.getDecoder().decode(sessionValue);
            Object value = JAVA_SER_HELPER.deserializeFromBytes(uncompressBytes(this.dataEncrypter.decrypt(inputBytes)));
            logger.trace("get, key = {} -> value = {}", key, value);
            return Optional.ofNullable(value);
        }
    }

    public void set(PlayWebContext context, String key, Object value) {
        logger.trace("set, key = {}, value = {}", key, value);
        Object clearedValue = value;
        if (key.contentEquals("pac4jUserProfiles")) {
            clearedValue = this.clearUserProfiles(value);
        }

        byte[] javaSerBytes = JAVA_SER_HELPER.serializeToBytes((Serializable)clearedValue);
        String serialized = Base64.getEncoder().encodeToString(this.dataEncrypter.encrypt(compressBytes(javaSerBytes)));
        if (serialized != null) {
            logger.trace("set, key = {} -> serialized token size = {}", key, serialized.length());
        } else {
            logger.trace("set, key = {} -> null serialized token", key);
        }

        context.setNativeSession(context.getNativeSession().adding("pac4j_" + key, serialized));
    }

    public boolean destroySession(PlayWebContext playWebContext) {
        return false;
    }

    public Optional<Object> getTrackableSession(PlayWebContext playWebContext) {
        return Optional.empty();
    }

    public Optional<SessionStore<PlayWebContext>> buildFromTrackableSession(PlayWebContext playWebContext, Object o) {
        return Optional.empty();
    }

    public boolean renewSession(PlayWebContext playWebContext) {
        return false;
    }

    protected Object clearUserProfiles(Object value) {
        LinkedHashMap<String, CommonProfile> profiles = (LinkedHashMap)value;
        profiles.forEach((name, profile) -> {
            profile.removeLoginData();
        });
        return profiles;
    }

    public static byte[] uncompressBytes(byte[] zippedBytes) {
        ByteArrayOutputStream resultBao = new ByteArrayOutputStream();

        try {
            GZIPInputStream zipInputStream = new GZIPInputStream(new ByteArrayInputStream(zippedBytes));

            byte[] var5;
            try {
                byte[] buffer = new byte[8192];

                while(true) {
                    int len;
                    if ((len = zipInputStream.read(buffer)) <= 0) {
                        var5 = resultBao.toByteArray();
                        break;
                    }

                    resultBao.write(buffer, 0, len);
                }
            } catch (Throwable var7) {
                try {
                    zipInputStream.close();
                } catch (Throwable var6) {
                    var7.addSuppressed(var6);
                }

                throw var7;
            }

            zipInputStream.close();
            return var5;
        } catch (IOException var8) {
            logger.error("Unable to uncompress session cookie", var8);
            return null;
        }
    }

    public static byte[] compressBytes(byte[] srcBytes) {
        ByteArrayOutputStream resultBao = new ByteArrayOutputStream();

        try {
            GZIPOutputStream zipOutputStream = new GZIPOutputStream(resultBao);

            try {
                zipOutputStream.write(srcBytes);
            } catch (Throwable var6) {
                try {
                    zipOutputStream.close();
                } catch (Throwable var5) {
                    var6.addSuppressed(var5);
                }

                throw var6;
            }

            zipOutputStream.close();
        } catch (IOException var7) {
            logger.error("Unable to compress session cookie", var7);
            return null;
        }

        return resultBao.toByteArray();
    }
}
