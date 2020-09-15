# live-streaming

Amazon Kinesis Video Streams WebRTC を使いやすくするためのラッパーライブラリ。Master と Viewer がある。

Master: 配信用。一人を想定。Master 用のアクセスキーは Master 用の権限を持つため外部に漏らさないこと。

Viewer: 視聴用。複数人を想定しているがあまりに多い人数には配信できない。Viewer 用のアクセスキーはソースコードに載せても良い。

## 使い方

### 配信、視聴のテストをするとき

それぞれ `master.html` と `viewer.html` を使用する。

### 視聴用ライブラリとして組み込むとき

`dist/viewer.js` を使いたいフォルダにコピーするなどして読み込む。

`new Viewer(options)`: options にアクセスキーなどの設定を渡す。

`viewer.start(videoElement)`: 通信を開始し、映像が来たら videoElement に渡す。

`viewer.stop()` 通信を切断する。

## 開発の仕方

もとのソースコードは Master を記述する `master.ts` と Viewer を記述する `viewer.ts` からなり、これをビルドする必要がある。

### 環境構築

```
npm install
```

### ビルド

```
npm run build:master
```

```
npm run build:viewer
```

## 依存ライブラリ

### aws-sdk

- https://github.com/aws/aws-sdk-js
- 使うのは KinesisVideo と KinesisVideoSignalingChannels だけなので個別にインポートする。

### amazon-kinesis-video-streams-webrtc

- https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-js
