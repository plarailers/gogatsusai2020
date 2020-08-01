# online
オンライン運転体験用のソースコードを置いたフォルダ。

## なかみ
### controller.html
(式部)ユーザーが操作するサイト。
ハンドルに見立てたスライダをユーザーが動かすと、<input type="range" id="speed" ...> のValueが、0-255の間で変化します。
<div id="message_area"> の部分は、パスワード入力欄などの要素を自由に置いて大丈夫です。message_areaの大きさが変化してもハンドルのサイズは自動で調整されます。

### style.css
(式部)controller.htmlのスタイルシート。