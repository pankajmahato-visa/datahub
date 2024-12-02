package com.visa.vdc;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;

public class FileUtil {

    private FileUtil() {
    }

    public static String readFile(String filename) throws IOException {
        //get the file object
        File file = FileUtils.getFile(filename);

        //get the content
        String data = FileUtils.readFileToString(file, Charset.defaultCharset());

        return data;
    }

    public static void writeFile(String filename, String data) throws IOException {
        //get the file object
        File file = FileUtils.getFile(filename);

        //get the content
        FileUtils.writeStringToFile(file, data, Charset.defaultCharset());
    }

}
