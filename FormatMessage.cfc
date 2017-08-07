component
{
		
		variables.baseURL = "";
		
		/** This function takes care of formatting the Mobile notification contents. It calls removeEmailContent to remove the content between <!-- EMAIL ONLY START -->  <!-- EMAIL ONLY END --> tags
		This function also removes all [server] links from the mobile notifications
		It also adds / to escape all quotes
		It also removes CR and LF from the message */
		public string function formatMobileContent (htmlString) {
			var newString = removeEmailContent (htmlString);
			newString =	removeanchorTags (newString);
			newString = modifyQuotes (newString);
			newString = removeCRLF(newString);
			return newString;
		}
		
		/** This function removes content specific to app message and removes anything that is between <!-- APP ONLY START --> and <!-- APP ONLY END --> tags. */
		public string function formatEmailContent (htmlString) {
			var newString = REReplaceNoCase(htmlString, '<!-- APP ONLY START -->.*<!-- APP ONLY END -->', '', "ALL");
			return newString;
		}

		/** This function generates an array of Actions for the message on the mobile app, it gives an array of struct consisting of the Action text and the corresponding link  */

		public array function getActionListText (htmlString) {
			var linkArray = getLinkArray (htmlString);
			var resultArray = [];
			for (link in linkArray) {
				if ( REFindNoCase('title="(.+?)".*?>',link) != 0 ){
					var tempString = REFindNoCase('title="(.+?)".*?>', link, 1, "True");
					var tempUrl = REFindNoCase('href="(.+?)"', link, 1, "True");
					var tempStruct = StructNew();
					StructInsert(tempStruct, tempString.match[2], tempUrl.match[2]);
					ArrayAppend(resultArray, tempStruct);
				} else if ( REFindNoCase('serviceid=(.+?)".*?>',link) != 0 ) {
					var tempString = REFindNoCase('serviceid=(.+?)".*?>', link, 1, "True");
					var tempUrl = REFindNoCase('href="(.+?)"', link, 1, "True");
					var serviceName = getServiceName (tempString.match[2]);
					var tempStruct = StructNew();
					StructInsert(tempStruct, serviceName, tempUrl.match[2]);
					ArrayAppend(resultArray, tempStruct);
				} else if ( REFindNoCase('>(.+?)</a>',link) != 0 ) {
					var tempString = REFindNoCase('>(.+?)</a>', link, 1, "True");
					var tempUrl = REFindNoCase('href="(.+?)"', link, 1, "True");
					var tempStruct = StructNew();
					StructInsert(tempStruct, tempString.match[2], tempUrl.match[2]);
					ArrayAppend(resultArray, tempStruct);
				} else {	
					var tempUrl = REFindNoCase('href="(.+?)"', link, 1, "True");
					var tempStruct = StructNew();
					StructInsert(tempStruct, "Take Action", tempUrl.match[2]);
					ArrayAppend(resultArray, tempStruct);
				}
			}
			return resultArray;
	 }


	 	/** Return the URL of the server, handles both split servers and single server */
		private void function getBaseUrl() {
			var baseName = CGI.HTTP_HOST;
			var baseURLSQL = "SELECT TOP 1 columnValue 
							FROM dbo.configBasePath";
			var lookupBaseURLInfo = new query(sql=baseURLSQL).execute().getResult();
			
			if( lookupBaseURLInfo.recordCount gt 0 ) {
				baseName = lookupBaseURLInfo.columnValue;
			}
			variables.baseURL = "https://" & #baseName# & "/";
		}

		/** Adds \ to escape quotes on the mobile message */
		private string function modifyQuotes (htmlString){
			var newString = REReplace( htmlString, "[""|']", '\"', "ALL" );
			return newString;
		}
		
		/** Removes email specific contents, anything in between tags <!-- EMAIL ONLY START --> <!-- EMAIL ONLY END --> will be removed */
		private string function removeEmailContent (htmlString) {
			var newString = REReplaceNoCase(htmlString, '<!-- EMAIL ONLY START -->.*<!-- EMAIL ONLY END -->', '', "ALL");
			return newString;
		}
		
		/** Removes Carriage Returns and Line Feeds */
		private string function removeCRLF (htmlString) {
			var newString = REReplaceNoCase(htmlString, '#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', "", "ALL");
			return newString;
		}

		/** Removes all anchor tags pointing to baseURL from the mobile message content */
		private string function removeanchorTags (htmlString) { 
			var linkArray = getLinkArray(htmlString);
			for (list in linkArray) {
				htmlString = Replace(htmlString, list, "", "ALL");
			}
			return htmlString;
		}
		
		/** Helper function to get the list of all anchor tags pointing to baseURL */
		private array function getLinkArray (htmlString) {
			getBaseUrl();
			var anchorArray = REMatchNoCase('<a[^>]*>.*?</a>',htmlString);
			var linkArray = [];
			for (link in anchorArray) {
				if ( REFindNoCase('href="#variables.baseURL#[^>].*?>.*?</a>',link) != 0 ) {
					ArrayAppend(linkArray, link);
				}
			}
			return linkArray;
		}
		
		/** Helper function which does a database lookup to fetch the service name for the given form service ID, also handles formGroup service IDs */
		private string function getServiceName (serviceID) {
			var serviceName = "Take Action";
			if ( REFindNoCase('formGroupProvider(.+?)',serviceID) != 0 ) {
				var tempId = REFindNoCase('formGroup=(.+?)',serviceID, 1, "True");
				
				var lookupEFormGroupTitle = new query();
				lookupEFormGroupTitle.setSql("SELECT title
												FROM dbo.formGroup
												WHERE recnum = :groupID");
				
				lookupEFormGroupTitle.addParam(name = 'groupID', cfsqltype="cf_sql_varchar", value = "#tempId.match[2]#");
				var groupTitleResults = lookupEFormGroupTitle.execute().getResult();
				if( groupTitleResults.recordCount gt 0 ) {
					serviceName = groupTitleResults.title;
				}
			} else {
				var lookupServiceNameInfo = new query();
				lookupServiceNameInfo.setSql( "SELECT TOP 1 serviceName
												FROM dbo.appServices
												WHERE serviceID = :serviceID");
				
				lookupServiceNameInfo.addParam( name = "serviceID", cfsqltype="cf_sql_varchar", value = serviceID );
				var serviceNameResults = lookupServiceNameInfo.execute().getResult();
				if( serviceNameResults.recordCount gt 0 ) {
					serviceName = serviceNameResults.serviceName;
				}
			}
			return serviceName;
		}

		/** This function makes database call and pulls datapoints from the configStationery table and maps them on the email template */
		public string function generateTemplate (recnum,checkList, alertGroup, campus) {
			var htmlValuesLookupSQL = "SELECT * FROM configEmailTemplateDefault";
			var resultString = fileRead(expandPath("/ui/template/email_template.html"));
			checkList = trim(checkList);
			alertGroup = trim(alertGroup);
			campus = trim(campus);
			recnum = trim(recnum);
			if (!IsNumeric(recnum)){
				recnum = 0;
			}
			// if ( len(checkList) != 0 || len(alertGroup) != 0 || len(campus) != 0 || IsNumeric(recnum) ) {
				var htmlValuesLookupQuery = new query();
				htmlValuesLookupQuery.setSql("SELECT 1 AS rank, officeNameBarColor, tagLineBarColor, addressBarColor, primaryFont, primaryFontFamily, primaryFontColor, secondaryFont, secondaryFontFamily, secondaryFontColor, logoImageSrc, officeNameText, officeWebsiteHref, taglineText, socialBarFacebookLink, socialBarTwitterLink, socialBarInstagramLink, socialBarYoutubeLink, addressBarText 
											  FROM configEmailTemplate 
											  WHERE recnum = :recnum 
									          UNION ALL
											  SELECT 2 AS rank, officeNameBarColor, tagLineBarColor, addressBarColor, primaryFont, primaryFontFamily, primaryFontColor, secondaryFont, secondaryFontFamily, secondaryFontColor, logoImageSrc, officeNameText, officeWebsiteHref, taglineText, socialBarFacebookLink, socialBarTwitterLink, socialBarInstagramLink, socialBarYoutubeLink, addressBarText 
											  FROM configEmailTemplate 
											  WHERE LEN(:checkList) > 0 AND checklist LIKE '%' + :checkList + ',%'
									          UNION ALL
									          SELECT 3 AS rank, officeNameBarColor, tagLineBarColor, addressBarColor, primaryFont, primaryFontFamily, primaryFontColor, secondaryFont, secondaryFontFamily, secondaryFontColor, logoImageSrc, officeNameText, officeWebsiteHref, taglineText, socialBarFacebookLink, socialBarTwitterLink, socialBarInstagramLink, socialBarYoutubeLink, addressBarText 
											  FROM configEmailTemplate 
											  WHERE LEN(:alertGroup) > 0 AND alertGroup LIKE '%' + :alertGroup + ',%'
									          UNION ALL
									          SELECT 4 AS rank, officeNameBarColor, tagLineBarColor, addressBarColor, primaryFont, primaryFontFamily, primaryFontColor, secondaryFont, secondaryFontFamily, secondaryFontColor, logoImageSrc, officeNameText, officeWebsiteHref, taglineText, socialBarFacebookLink, socialBarTwitterLink, socialBarInstagramLink, socialBarYoutubeLink, addressBarText 
											  FROM configEmailTemplate 
											  WHERE LEN(:campus) > 0 AND campus LIKE '%' + :campus + ',%'
									          ORDER BY rank");
				
				htmlValuesLookupQuery.addParam( name = "recnum", cfsqltype="cf_sql_varchar", value = recnum );
				htmlValuesLookupQuery.addParam( name = "checkList", cfsqltype="cf_sql_varchar", value = checkList );
				htmlValuesLookupQuery.addParam( name = "alertGroup", cfsqltype="cf_sql_varchar", value = alertGroup );
				htmlValuesLookupQuery.addParam( name = "campus", cfsqltype="cf_sql_varchar", value = campus );
				var htmlValuesLookupResults = htmlValuesLookupQuery.execute().getResult();
				//writedump("htmlValuesLookupResults");
				if ( htmlValuesLookupResults.recordCount gt 0 ) {
					var htmlDataPointsColumnNames = htmlValuesLookupResults.getColumnList();
					for (dataPoint in htmlDataPointsColumnNames) {
						tempColumnValue = htmlValuesLookupResults[dataPoint][1];
						if ( REFindNoCase('#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', tempColumnValue) != 0 ){
							tempColumnValue = REReplaceNoCase(tempColumnValue, '#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', "<br/>", "ALL");
						}
						resultString = ReplaceNoCase(resultString, '%'&dataPoint&'%', tempColumnValue, 'ALL');
					}
				} else {
					var htmlValuesLookupQuery = new query(sql=htmlValuesLookupSQL).execute().getResult();
					if ( htmlValuesLookupQuery.recordCount gt 0 ) {
						var htmlDataPointsColumnNames = htmlValuesLookupQuery.getColumnList();
						for (dataPoint in htmlDataPointsColumnNames) {
							tempColumnValue = htmlValuesLookupQuery[dataPoint][1];
							if ( REFindNoCase('#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', tempColumnValue) != 0 ){
								tempColumnValue = REReplaceNoCase(tempColumnValue, '#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', "<br/>", "ALL");
							}
							resultString = ReplaceNoCase(resultString, '%'&dataPoint&'%', tempColumnValue, 'ALL');
						}
					}
				}
			// } else {
			// 	var htmlValuesLookupQuery = new query(sql=htmlValuesLookupSQL).execute().getResult();
			// 	if ( htmlValuesLookupQuery.recordCount gt 0 ) {
			// 		var htmlDataPointsColumnNames = htmlValuesLookupQuery.getColumnList();
			// 		for (dataPoint in htmlDataPointsColumnNames) {
			// 			tempColumnValue = htmlValuesLookupQuery[dataPoint][1];
			// 			if ( REFindNoCase('#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', tempColumnValue) != 0 ){
			// 				tempColumnValue = REReplaceNoCase(tempColumnValue, '#chr(13)##chr(10)#|\r\n|#chr(13)#|#chr(10)#|\n|\r', "<br/>", "ALL");
			// 			}
			// 			resultString = ReplaceNoCase(resultString, '%'&dataPoint&'%', tempColumnValue, 'ALL');
			// 		}
			// 	}
			// }
			return resultString;
		}
}
