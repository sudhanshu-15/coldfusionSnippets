<cfscript>
try{
    component = CreateObject("component", "FormatMessage");
    recnum = url.templateid;
    if (IsNumeric(recnum) AND recnum >= 0){

        outputHtml = component.generateTemplate (recnum,'', '', '');
        body = component.getEmailBody(2);

        templateContent = '<p align="center" class="content-wrapper main-content-copy" style="background-color:##ffffff; padding:100px 25px 100px 25px; margin:0; font-family: Arial, Helvetica, sans-serif; color: ##414042; font-size: 18px; line-height:28px;" valign="top" width="425"> #body# </p> ';

        outputHtml = ReplaceNoCase(outputHtml, '%emailContent%', templateContent, 'ALL');

        WriteOutput(outputHtml);

    } else {

        writedump ('Invalid templateid');

    }
} catch (any exception) {
    writedump(exception);
}
</cfscript>