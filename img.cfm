<cfscript>
try{
    if( StructKeyExists(url, 'idnumber')  && StructKeyExists(url, 'correspondenceId') && StructKeyExists(url, 'communicationType')) {
        if(IsNumeric(url.idnumber) && IsNumeric(url.correspondenceId) && (trim(url.communicationType) eq 'mobile' || trim(url.communicationType) eq 'web' || trim(url.communicationType) eq 'email' )){
            try{
                limitUpdateQuery = new query();
                limitUpdateQuery.setSql("SELECT * FROM correspondenceRead
                                        WHERE idnumber = :idnumber
                                        AND  correspondenceId = :correspondenceId
                                        AND datestamp >= dateadd(minute, -15, current_timestamp)");
                limitUpdateQuery.addParam( name = "idnumber", cfsqltype="cf_sql_varchar", value = url.idnumber );
                limitUpdateQuery.addParam( name = "correspondenceId", cfsqltype="cf_sql_varchar", value = url.correspondenceId );
                result = limitUpdateQuery.execute().getResult();
                writedump(result);
                if(result.recordCount eq 0){
                    updateTrackingQuery = new query();
                    updateTrackingQuery.setSql("INSERT INTO correspondenceRead(idnumber, correspondenceId, communicationType, datestamp) VALUES (#url.idnumber#, #url.correspondenceId#, N'#url.communicationType#', CURRENT_TIMESTAMP)");
                    updateresult = updateTrackingQuery.execute().getResult();
                }
                imageFile = "#GetDirectoryFromPath(expandPath('/ui/template/'))#img.jpg";
                cfcontent(type="image/jpeg", file="#imageFile#");
            }catch (any exception) {
                writedump(exception);
            }
        }
    }
}catch (any exception) {
writedump(exception);
}
</cfscript>