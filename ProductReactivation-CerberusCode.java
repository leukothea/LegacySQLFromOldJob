package com.charityusa.reports.ecommerce;

import com.charityusa.report.util.OutputPathNormalizer;
import com.charityusa.reports.MailedReport;
import com.charityusa.sql.JDBCPostgresConnection;
import com.charityusa.sql.SelectSQLBuilder;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFRichTextString;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Properties;

/**
* Created by IntelliJ IDEA.
* User: doug
* Date: Sep 2, 2010
* Time: 9:59:24 AM
*/
public class ProductReactivation extends MailedReport {
    private static final Logger logger = LoggerFactory.getLogger(ProductReactivation.class);

    public ProductReactivation() {

    }

    public static void main(final String[] args) {
        final CommandLine cmd = parseParameters(args);

        // now lets interrogate the options and execute the relevant parts
        if (cmd.hasOption("m")) {
            sendMail = Boolean.TRUE;
        }
        final String basepath = System.getProperty("report.basepath");
        new ProductReactivation().init(basepath);
    }

    private static CommandLine parseParameters(final String[] args) {
        // create the Options object
        final Options options = new Options();

        final Option mailOption = new Option("m", false, " send email to full list");
        mailOption.setRequired(false);
        options.addOption(mailOption);

        // now lets parse the input
        final CommandLineParser parser = new DefaultParser();
        CommandLine cmd = null;
        try {
            cmd = parser.parse(options, args);
        } catch (final ParseException pe) {
            usage(options);
        }
        return cmd;
    }

    private static void usage(final Options options) {
        // Use the inbuilt formatter class
        final HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("ProductReactivation", options);
        System.exit(0);
    }

    public void init(final String basepath) {
        // Not using our ConnectionHolder stuff here, not really necessary and it complicates the sybase -> postgres transition...
        final JDBCPostgresConnection jcon = new JDBCPostgresConnection();
        Collection<Properties> results = null;
        Collection<Properties> results2 = null;
        Collection<Properties> results3 = null;
        try (final Connection con = jcon.createConnectionFromXMLFileNamed("connect_charityusa.xml")) {
            final SelectSQLBuilder sqlProcessor = new SelectSQLBuilder();

            sqlProcessor.setSelect("select distinct i.item_id,its.itemstatus,pv.productversion_id,sts.itemstatus as skustatus,pv.name");
            sqlProcessor.setFrom("from ecommerce.item as i,ecommerce.itemstatus as its,ecommerce.itemstatus as sts,ecommerce.productversion as pv");
            sqlProcessor.appendFrom("ecommerce.productversionsku as pvs, ecommerce.sku as s, ecommerce.rsinventoryitem ii");
            sqlProcessor.setWhere("where i.item_id = pv.item_id and i.vendor_id in (60,83)");
            sqlProcessor.appendWhere("i.itemstatus_id in (0,1,5,8) and i.itemstatus_id = its.itemstatus_id");
            sqlProcessor.appendWhere("pv.productversion_id = pvs.productversion_id and pv.itemstatus_id in (1)");
            sqlProcessor.appendWhere("pvs.sku_id = s.sku_id and s.itemstatus_id = sts.itemstatus_id");
            sqlProcessor.appendWhere("s.itemstatus_id = 0 and s.sku_id = ii.sku_id and not s.name like 'FP -%'");
            sqlProcessor.appendWhere("pv.initiallaunchdate is not null");
            sqlProcessor.appendWhere("ii.quantity > 0 and ii.active = true");
            //       sqlProcessor.appendWhere("pv.productversion_id not in (select pv.productversion_id from ecommerce.productversion as pv,ecommerce.item as i where pv.item_id = i.item_id and i.itemstatus_id in (0,1))");
            sqlProcessor.appendWhere("pv.productversion_id not in (select pvs.productversion_id from ecommerce.productversionsku as pvs,ecommerce.sku as s where pvs.sku_id = s.sku_id and s.itemstatus_id in (1,5,8))");
            sqlProcessor.setOrderBy("order by its.itemstatus,i.item_id");

            results = collectionFromSql(con, sqlProcessor.queryString());
            final SelectSQLBuilder itemProcessor = new SelectSQLBuilder();

            itemProcessor.setSelect("select distinct i.item_id,i.name");
            itemProcessor.setFrom("from ecommerce.item as i,ecommerce.productversion as pv,ecommerce.productversionsku pvs,ecommerce.sku s");
            itemProcessor.setWhere("where i.item_id = pv.item_id and pv.productversion_id = pvs.productversion_id and pvs.sku_id = s.sku_id and not s.name like 'FP -%'");
            itemProcessor.appendWhere("i.itemstatus_id = 1 and pv.itemstatus_id = 0");
            itemProcessor.setOrderBy("order by i.item_id");

            results2 = collectionFromSql(con, itemProcessor.queryString());

            final SelectSQLBuilder kitProcessor = new SelectSQLBuilder();
            kitProcessor.setSelect("select pvs.sku_id,count(*)");
            kitProcessor.setFrom("from ecommerce.productversionsku as pvs,ecommerce.sku s");
            kitProcessor.setWhere("where pvs.sku_id = s.sku_id and not s.name like 'FP -%'");
            kitProcessor.setGroupBy("group by pvs.sku_id");
            kitProcessor.setHaving("having count(*) = 1");

            final SelectSQLBuilder versionProcessor = new SelectSQLBuilder();
            versionProcessor.setSelect("select i.item_id,pv.productversion_id as version_id,pv.name as version_name ,s.sku_id,s.name as sku_name,sum (rs.quantity) as inventory");
            versionProcessor.setFrom("from ecommerce.item as i, ecommerce.sku as s, ecommerce.productversion as pv, ecommerce.productversionsku as pvs, ecommerce.rsinventoryitem as rs");
            versionProcessor.appendRelationToFromWithAlias(kitProcessor, "qs");
            versionProcessor.setWhere("where i.vendor_id = 83 and i.item_id = pv.item_id and pv.productversion_id = pvs.productversion_id");
            versionProcessor.appendWhere("pvs.sku_id = s.sku_id and s.sku_id = qs.sku_id and s.sku_id = rs.sku_id and not s.name like 'FP -%'");
            versionProcessor.appendWhere("s.itemstatus_id = 0 and pv.itemstatus_id = 5 and i.itemstatus_id IN (0, 1)");
            versionProcessor.setGroupBy("group by i.item_id,pv.productversion_id,pv.name,s.sku_id,s.name");
            versionProcessor.setHaving("having sum (rs.quantity) > 0");
            versionProcessor.setOrderBy("order by s.sku_id desc");

            results3 = collectionFromSql(con, versionProcessor.queryString());
        } catch (final SQLException e) {
            logger.error("SQLException during query execution or connection cleanup");
        }
        if (results == null || results.isEmpty() || results2 == null || results2.isEmpty() || results3 == null || results3.isEmpty()) {
            logger.info("No Products found needing reactivation");
        }
        // OK, we have our results, time to build up both of the attachments...
        // decided to use poi here, and build an excel workbook up with 2 sheets.
        final OutputPathNormalizer opn = new OutputPathNormalizer();

        final StringBuilder output = new StringBuilder(opn.checkNormalOutputPath(basepath));
        output.append("ProductReactivation.xlsx");

        // create a new workbook
        final SXSSFWorkbook wb = new SXSSFWorkbook();
        // create 3 cell styles
        final CellStyle cs = wb.createCellStyle();
        final CellStyle cs2 = wb.createCellStyle();
        // create 2 fonts objects
        final Font f = wb.createFont();
        final Font f2 = wb.createFont();

        //set font 1 to 12 point type
        f.setFontHeightInPoints((short) 12);
        // make it bold
        //arial is the default font
        f.setBoldweight(Font.BOLDWEIGHT_BOLD);

        //set font 2 to 10 point type
        f2.setFontHeightInPoints((short) 10);

        //set cell style
        cs.setFont(f);
        //set cell style
        cs2.setFont(f2);

        // create a new sheet
        final Sheet s = wb.createSheet();
        wb.setSheetName(0, "ProductVersions for Reactivation");
        processSheet(s, results, cs, cs2);
        final Sheet s2 = wb.createSheet();
        wb.setSheetName(1, "Items for Reactivation");
        processSheet2(s2, results2, cs, cs2);
        final Sheet s3 = wb.createSheet();
        wb.setSheetName(2, "Retired Versions with Active Skus");
        processSheet3(s3, results3, cs, cs2);

        try (FileOutputStream out = new FileOutputStream(output.toString())) {
            // create a new file
            wb.write(out);
        } catch (final FileNotFoundException fn) {
            logger.error("FileNotFoundException while creating excel output");
        } catch (final IOException ie) {
            logger.error("IOException while writing to output file.");
        }

        wb.dispose();
        final StringBuilder subject = new StringBuilder("Product Reactivation Notice -- ").append(opn.getFullDatePath());
        deliverReport(subject.toString(), "Items and ProductVersions that need to be evaluated for activation.", new File(output.toString()), "ncrowder@greatergood.com,rachel@greatergood.com,celia@greatergood.com,emueller@greatergood.com", "mikea@greatergood.com");
    }

    protected void processSheet(final Sheet sheet, final Iterable<Properties> results, final CellStyle cs, final CellStyle cs2) {
        // create a row
        final Row headerRow = sheet.createRow(0);
        final String[] headerStrings = {"ItemId", "ItemStatus", "ProductVersionId", "SkuStatus", "VersionName"};
        int s = 0;
        for (final String title : headerStrings) {
            final Cell headerCell = headerRow.createCell(s);
            headerCell.setCellStyle(cs);
            headerCell.setCellValue(new XSSFRichTextString(title));
            s++;
        }

        final String[] aliasStrings = {"item_id", "itemstatus", "productversion_id", "skustatus", "name"};

        short rownum = 1;
        for (final Properties result : results) {
            // create a row
            final Row dataRow = sheet.createRow(rownum);
            int column = 0;
            for (final String alias : aliasStrings) {
                final Cell dataCell = dataRow.createCell(column);
                dataCell.setCellStyle(cs2);
                dataCell.setCellValue(new XSSFRichTextString(result.getProperty(alias)));
                column++;
            }
            rownum++;
        }
        for (short f = 0; f < headerStrings.length; f++) {
            try{
                sheet.autoSizeColumn(f);
            }catch(Exception e){}
        }
    }

    protected void processSheet2(final Sheet sheet, final Iterable<Properties> results, final CellStyle cs, final CellStyle cs2) {
        // create a row
        final Row headerRow = sheet.createRow(0);
        final String[] headerStrings = {"ItemId", "ItemName"};
        int s = 0;
        for (final String title : headerStrings) {
            final Cell headerCell = headerRow.createCell(s);
            headerCell.setCellStyle(cs);
            headerCell.setCellValue(new XSSFRichTextString(title));
            s++;
        }

        final String[] aliasStrings = {"item_id", "name"};

        short rownum = 1;
        for (final Properties result : results) {
            // create a row
            final Row dataRow = sheet.createRow(rownum);
            int column = 0;
            for (final String alias : aliasStrings) {
                final Cell dataCell = dataRow.createCell(column);
                dataCell.setCellStyle(cs2);
                dataCell.setCellValue(new XSSFRichTextString(result.getProperty(alias)));
                column++;
            }
            rownum++;
        }
        for (short f = 0; f < headerStrings.length; f++) {
            try{
                sheet.autoSizeColumn(f);
            }catch(Exception e){}
        }
    }

    protected void processSheet3(final Sheet sheet, final Iterable<Properties> results, final CellStyle cs, final CellStyle cs2) {
        // create a row
        final Row headerRow = sheet.createRow(0);
        final String[] headerStrings = {"ItemId", "VersionId", "VersionName", "SkuId", "SkuName", "Inventory"};
        int s = 0;
        for (final String title : headerStrings) {
            final Cell headerCell = headerRow.createCell(s);
            headerCell.setCellStyle(cs);
            headerCell.setCellValue(new XSSFRichTextString(title));
            s++;
        }

        final String[] aliasStrings = {"item_id", "version_id", "version_name", "sku_id", "sku_name", "inventory"};

        short rownum = 1;
        for (final Properties result : results) {
            // create a row
            final Row dataRow = sheet.createRow(rownum);
            int column = 0;
            for (final String alias : aliasStrings) {
                final Cell dataCell = dataRow.createCell(column);
                dataCell.setCellStyle(cs2);
                dataCell.setCellValue(new XSSFRichTextString(result.getProperty(alias)));
                column++;
            }
            rownum++;
        }
        for (short f = 0; f < headerStrings.length; f++) {
            try {
                sheet.autoSizeColumn(f);
            }catch(Exception e){}

        }
    }
}