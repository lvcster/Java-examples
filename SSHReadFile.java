package sshproject;

/**
 * https://stackoverflow.com/questions/3071760/ssh-connection-with-java
 * https://www.journaldev.com/246/jsch-example-java-ssh-unix-server
 * https://sourceforge.net/projects/jsch/
 * https://www.example-code.com/java/ssh.asp
 * http://www.java2s.com/Code/Jar/j/Downloadjsch015jar.htm
 */
import java.io.InputStream;

import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import java.io.InputStreamReader;
import java.util.Scanner;

public class SSHReadFile {

    public static void main(String args[]) {
        String user = "john";
        String password = "mypassword";
        String host = "192.168.100.23";
        int port = 22;
        String remoteFile = "/home/john/test.txt";

        try {
            JSch jsch = new JSch();
            Session session = jsch.getSession(user, host, port);
            session.setPassword(password);
            session.setConfig("StrictHostKeyChecking", "no");
            System.out.println("Establishing Connection...");
            session.connect();
            System.out.println("Connection established.");
            System.out.println("Crating SFTP Channel.");
            ChannelSftp sftpChannel = (ChannelSftp) session.openChannel("sftp");
            sftpChannel.connect();
            System.out.println("SFTP Channel created.");

            InputStream inputStream = sftpChannel.get(remoteFile);

            try (Scanner scanner = new Scanner(new InputStreamReader(inputStream))) {
                while (scanner.hasNextLine()) {
                    String line = scanner.nextLine();
                    System.out.println(line);
                }
            }
        } catch (JSchException | SftpException e) {//catch (JSchException | SftpException e) {
            e.printStackTrace();
        }
    }
}