import "dart:async";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

import "package:googleapis/youtube/v3.dart";
import 'package:googleapis_auth/auth_io.dart';

LinkProvider link;
AuthClient googleAuthClient;
YoutubeApi youtube;

main(List<String> args) async {
  googleAuthClient = clientViaApiKey("AIzaSyBAWrEREoLjbmBd6gbwSzfV7uEQJvQVTOw");
  youtube = new YoutubeApi(googleAuthClient);

  link = new LinkProvider(args, "YouTube-", command: "run", defaultNodes: {
    "Get_Channel_Videos": {
      r"$name": "Get Channel Videos",
      r"$is": "getChannelVideos",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "channel",
          "type": "string"
        }
      ],
      r"$result": "table",
      r"$columns": [
        {
          "name": "id",
          "type": "string"
        },
        {
          "name": "title",
          "type": "string"
        },
        {
          "name": "description",
          "type": "string"
        },
        {
          "name": "thumbnail",
          "type": "string"
        },
        {
          "name": "published",
          "type": "string"
        }
      ]
    },
    "Get_Channel_Playlists": {
      r"$name": "Get Channel Playlists",
      r"$is": "getChannelPlaylists",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "channel",
          "type": "string"
        }
      ],
      r"$result": "table",
      r"$columns": [
        {
          "name": "id",
          "type": "string"
        },
        {
          "name": "title",
          "type": "string"
        },
        {
          "name": "description",
          "type": "string"
        },
        {
          "name": "thumbnail",
          "type": "string"
        },
        {
          "name": "published",
          "type": "string"
        }
      ]
    },
    "Get_View_Count": {
      r"$name": "Get View Count",
      r"$is": "getViewCount",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "id",
          "type": "string"
        }
      ],
      r"$columns": [
        {
          "name": "views",
          "type": "int"
        }
      ]
    }
  }, profiles: {
    "getChannelVideos": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      if (params["channel"] == null) [];

      var response = await youtube.search.list("snippet,id", channelId: params["channel"], order: "date");
      return response.items.where((it) => it.id.kind == "youtube#video").map((SearchResult it) => {
        "id": it.id.videoId,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString()
      });
    }),
    "getViewCount": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      var id = params["id"];
      if (id == null) return {};
      VideoListResponse videos = await youtube.videos.list("statistics", id: id);
      return {
        "views": videos.items[0].statistics.viewCount
      };
    }),
    "getChannelPlaylists": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) async {
      if (params["channel"] == null) [];

      PlaylistListResponse response = await youtube.playlists.list("snippet,id", channelId: params["channel"]);
      return response.items.map((Playlist it) => {
        "id": it.id,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString()
      });
    })
  });

  link.connect();
}
