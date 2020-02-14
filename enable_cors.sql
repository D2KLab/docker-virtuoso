update DB.DBA.HTTP_PATH set HP_OPTIONS = serialize(vector('browse_sheet', '', 'noinherit', 'yes', 'cors', '*', 'cors_restricted', 0))  where HP_LPATH = '/sparql';
