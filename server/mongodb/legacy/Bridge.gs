/** Replace deployed Code.gs only at the final cutover. No spreadsheet writes. */
function doPost(e) {
  const json = data => ContentService.createTextOutput(JSON.stringify(data)).setMimeType(ContentService.MimeType.JSON);
  try {
    if (!e || !e.postData || e.postData.contents.length > 8192) return json({ok: false, error: 'invalid_request'});
    const props = PropertiesService.getScriptProperties();
    if (props.getProperty('MIGRATION_MAINTENANCE') === 'true') return json({ok: false, error: 'busy'});
    const endpoint = props.getProperty('MONGO_API_URL');
    if (!endpoint || !/^https:\/\//.test(endpoint)) return json({ok: false, error: 'not_configured'});
    const response = UrlFetchApp.fetch(endpoint, {method: 'post', contentType: 'application/json',
      payload: e.postData.contents, followRedirects: false, muteHttpExceptions: true});
    if (response.getResponseCode() !== 200) return json({ok: false, error: 'service_error'});
    const result = JSON.parse(response.getContentText());
    if (!result || typeof result.ok !== 'boolean') return json({ok: false, error: 'service_error'});
    return json(result);
  } catch (_) {
    console.error('MongoDB bridge request failed');
    return json({ok: false, error: 'service_error'});
  }
}
