import "package:dslink/client.dart";
import "package:dslink/responder.dart";

import "package:googleapis/youtube/v3.dart";
import 'package:googleapis_auth/auth_io.dart';

LinkProvider link;
AuthClient googleAuthClient;
YoutubeApi youtube;

main(List<String> args) async {
  googleAuthClient = clientViaApiKey("AIzaSyBAWrEREoLjbmBd6gbwSzfV7uEQJvQVTOw");
  youtube = new YoutubeApi(googleAuthClient);

  link = new LinkProvider(args, "YouTube-", command: "run", defaultNodes: {
    "Get Channel Videos": {
      r"$is": "getChannelVideos",
      r"$invokable": "read",
      r"$params": [
        {
          "name": "channel",
          "type": "string"
        },
        {
          "name": "count",
          "type": "integer",
          "default": 20
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
    }
  }, profiles: {
    "getChannelVideos": (String path) => new GetChannelVideosNode(path)
  });

  if (link.link == null) return;

  link.connect();
}

class GetChannelVideosNode extends SimpleNode {
  GetChannelVideosNode(String path) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    if (params["channel"] == null) return new AsyncTableResult()..close();

    var r = new AsyncTableResult();
    youtube.search.list("snippet,id", channelId: params["channel"], order: "date").then((response) {
      r.update(response.items.where((it) => it.id.kind == "youtube#video").map((SearchResult it) => {
        "id": it.id.videoId,
        "title": it.snippet.title,
        "description": it.snippet.description,
        "thumbnail": it.snippet.thumbnails.default_.url,
        "published": it.snippet.publishedAt.toString()
      }).toList());
      r.close();
    });
    return r;
  }
}
