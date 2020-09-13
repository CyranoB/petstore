import java.security.Key;

import javax.crypto.Cipher;

public class CryptoUtil {

	public static String decryptRSA(byte[] text, Key key) {
		byte[] dectyptedText = null;
		try {
			final Cipher cipher = Cipher.getInstance("RSA");
			cipher.init(Cipher.DECRYPT_MODE, key);
			dectyptedText = cipher.doFinal(text);

		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
		return new String(dectyptedText);
	}

	public static byte[] encryptRSA(String rand, Key key) {
		byte[] cipherText = null;
		try {
			final Cipher cipher = Cipher.getInstance("RSA");
			cipher.init(Cipher.ENCRYPT_MODE, key);
			cipherText = cipher.doFinal(rand.getBytes());
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		return cipherText;
	}

}
