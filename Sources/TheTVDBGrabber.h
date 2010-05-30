/*
 *  TheTVDBGrabber.h
 *  Lunettes
 *
 *  Created by Pierre d'Herbemont on 5/24/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#define TVDB_DEFAULT_LANGUAGE   "en"

#define TVDB_HOSTNAME           "thetvdb.com"
#define TVDB_IMAGES_HOSTNAME    "thetvdb.com"

#define TVDB_API_KEY            "EACB874D8C2A90E2"

/* See http://thetvdb.com/wiki/index.php?title=Programmers_API */
#define TVDB_QUERY_SEARCH       @"http://%s/api/GetSeries.php?seriesname=%@"
#define TVDB_QUERY_SEARCH_NEW   @"http://%s/api/GetSeriesNew.php?seriesname=%@"
#define TVDB_QUERY_SERVER_TIME  @"http://%s/api/Updates.php?type=none"
#define TVDB_QUERY_UPDATES      @"http://%s/api/Updates.php?type=all&time=%@"
#define TVDB_QUERY_INFO         @"http://%s/api/%s/series/%@/%s.xml"
#define TVDB_QUERY_EPISODE_INFO @"http://%s/api/%s/series/%@/all/%s.xml"
#define TVDB_COVERS_URL         @"http://%s/banners/%@"
