# live-streaming

Amazon Kinesis Video Streams を使いやすくするためのラッパーライブラリ。

Master: 配信用

Viewer: 視聴用

## 使い方

配信、視聴のテストをするときはそれぞれ `master.html` と `viewer.html` を使用する。

視聴用ライブラリとして組み込むときは、 `dist/viewer.js` を使いたいフォルダにコピーするなどして読み込む。

## 環境構築

```
npm install
```

## ビルド

```
parcel build:master
```

```
parcel build:viewer
```

## 依存ライブラリ

### aws-sdk

- https://github.com/aws/aws-sdk-js
- 使うのは KinesisVideo と KinesisVideoSignalingChannels だけなので個別にインポートする。

### amazon-kinesis-video-streams-webrtc

- https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-js
