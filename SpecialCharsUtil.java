/*
 *https://www.javacodex.com/Strings/Find-Special-Characters-In-A-String
 *https://www.regular-expressions.info/java.html
 */

import java.util.regex.Matcher;
import java.util.regex.Pattern;
 
public class SpecialCharsUtil {
 
   public static void main(String[] args) {
 
      String str = "abc$def^ghi#jkl";
 
      Pattern p = Pattern.compile("[^a-z0-9 ]", Pattern.CASE_INSENSITIVE);
      Matcher m = p.matcher(str);
 
      System.out.println(str);
      int count = 0;
      while (m.find()) {
         count = count+1;
         System.out.println("position "  + m.start() + ": " + str.charAt(m.start()));
      }
      System.out.println("There are " + count + " special characters");
   }
}