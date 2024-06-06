import java.io.BufferedWriter;
import java.io.File;
import java.lang.Exception;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.util.ArrayList;
import java.nio.charset.StandardCharsets;
import java.io.OutputStreamWriter;
import java.io.FileOutputStream;

public class Extractor {
    public static void main(String[] args) throws Exception {
        // args = new
        // String[]{"T:/sync/gdrive/ezrasLegacy/v4/g/godot/addons/GnumarusStaticDataImporter/Examples/SampleOdb.odb"};//deleteme
        if (args.length < 1) {
            return;
        }

        String inFilePath = args[0].trim();
        if (inFilePath.isEmpty()) {
            return;
        }

        File file = new File(inFilePath);
        if (!file.isFile()) {
            return;
        }

        if (inFilePath.endsWith(".odb")) {
            processOdb(inFilePath);
        }
    }

    public static void processOdb(String odbAbsPath) throws Exception {
        // needs hsqldb jar to connect to an hsqldb database (which is used by
        // libreoffice base)
        // libreoffice odb uses an old hsql version, 1.8, provided by
        // hsqldb-1.8.0.10.jar
        // newer is hsqldb-2.7.3.jar (as of 06/2024) but it does not work with 1.8
        // databases
        Class.forName("org.hsqldb.jdbcDriver");

        String mttsvAbsPath = odbAbsPath + ".mttsv.tmp";
        String hsqldbAbsPath = odbAbsPath + "_hsqldbdata\\db";

        Connection con = null;
        con = DriverManager.getConnection("jdbc:hsqldb:file:" + hsqldbAbsPath);

        Statement statement = con.createStatement();
        String tablesQuery = "select * from information_schema.system_tables";
        ResultSet tablesRS = statement.executeQuery(tablesQuery);

        ArrayList<Object> tmpRow = new ArrayList<Object>();
        BufferedWriter writer = new BufferedWriter(
                new OutputStreamWriter(new FileOutputStream(mttsvAbsPath, false), StandardCharsets.UTF_8));
        writer.write("multitable\n");
        while (tablesRS.next()) {
            tmpRow.clear();
            String schema = tablesRS.getString("TABLE_SCHEM");
            if (schema == "INFORMATION_SCHEMA" || schema == "SYSTEM_LOBS") {
                continue;
            }
            String quotedSchema = quotify(schema);

            String table = tablesRS.getString("TABLE_NAME");
            String quotedTable = quotify(table);

            String tableWithSchema = schema + "." + table;
            String quotedTableWithSchema = quotedSchema + "." + quotedTable;

            String rowsQuery = "select * from " + quotedTableWithSchema;
            ResultSet rowsRS = statement.executeQuery(rowsQuery);
            ResultSetMetaData rowsRSMD = rowsRS.getMetaData();

            int colCount = rowsRSMD.getColumnCount();
            String line = "";
            for (int i = 1; i <= colCount; i++) {
                line += rowsRSMD.getColumnName(i) + '\t';
            }
            line = line.substring(0, line.length() - 1);

            writer.write(tableWithSchema.replace(".", "_") + "\n");
            writer.write(line + "\n");
            line = "";
            tmpRow.clear();
            while (rowsRS.next()) {
                for (int i = 1; i <= colCount; i++) {
                    Object o = rowsRS.getObject(i);
                    if (o != null) {
                        String s = o.toString();
                        if (s.contains("\"")) {
                            s = s.replace("\"", "\"\"");
                            s = quotify(s);
                        } else if (s.contains("\t")) {
                            s = quotify(s);
                        }
                        line += s;
                    }
                    line += '\t';
                }
                line = line.substring(0, line.length() - 1);
                writer.write(line + "\n");
            }
            writer.write("\n");
        }
        // writer.write("\n_平仮名😀嶲_\n"); // do not work as expected. with no amount of
        // conversions constructing new strings with getbytes I was able to print it
        // correctly to the file. fortunately I actually don't need this, I was just
        // testing =P
        // writer.write(new String("\n_平仮名😀嶲_\n".getBytes(StandardCharsets.UTF_8),
        // StandardCharsets.UTF_16)); // also doesn't work
        writer.close();
        statement.close();
        con.close();
    }

    public static void println(Object pObj) {
        System.out.println(pObj);
    }

    public static String quotify(String s) {
        return "\"" + s + "\"";
    }
}

// https://programmaremobile.blogspot.com/2009/01/java-and-openoffice-base-db-through.html
// https://mvnrepository.com/artifact/org.hsqldb/hsqldb/2.7.3
// https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.7.3/hsqldb-2.7.3.jar
// https://mvnrepository.com/artifact/org.hsqldb/hsqldb/1.8.0.10
// https://repo1.maven.org/maven2/org/hsqldb/hsqldb/1.8.0.10/hsqldb-1.8.0.10.jar
