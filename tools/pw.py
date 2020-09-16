# パスワードの初期データを与えたりする。
#
# 最初に以下を実行する。
#   pip install boto3 python-dateutil
#
# データ一覧
#   python tools/pw.py scan
#
# 初期データ生成（表示のみ）
#   python tools/pw.py generate
#
# 初期データ生成（データベースに突っ込む）
#   python tools/pw.py generate_and_write
#
# データ削除（5分間のもののみ）
#   python tools/pw.py clear

import sys
import random
import datetime
import dateutil.parser
import boto3

dynamoDB = boto3.resource('dynamodb')
table = dynamoDB.Table('gogatsusai2020-backend-passwords-dev')

def scan():
    data = table.scan()
    print(len(data['Items']), 'items found')
    for item in data['Items']:
        print(item)
    print('done')

def generate(write=False):
    start_time_list = []
    # 9/20 9:00 から 10 分おきに、18:00 まで
    start_time_list.extend((2020, 9, 20, h, m, 0) for h in range(9, 18) for m in range(0, 60, 10))
    # 9/21 9:00 から 10 分おきに、18:00 まで
    start_time_list.extend((2020, 9, 21, h, m, 0) for h in range(9, 18) for m in range(0, 60, 10))
    JST = datetime.timezone(datetime.timedelta(hours=+9))
    items = []
    for start_time in start_time_list:
        # 数字4桁 + 英大文字1文字
        password = '%04d%c' % (random.randint(0000, 9999), random.randint(ord('A'), ord('Z')))
        start_time = datetime.datetime(*start_time, tzinfo=JST)
        end_time = start_time + datetime.timedelta(minutes=5)
        items.append({
            'Password': password,
            'StartTime': start_time.isoformat(),
            'EndTime': end_time.isoformat()
        })
        print(password, start_time.isoformat(), end_time.isoformat())
    if write:
        with table.batch_writer() as batch:
            for item in items:
                batch.put_item(Item=item)
    print('done')

def clear():
    data = table.scan()
    items = data['Items']
    with table.batch_writer() as batch:
        for item in items:
            start_time = dateutil.parser.parse(item['StartTime'])
            end_time = dateutil.parser.parse(item['EndTime'])
            if start_time + datetime.timedelta(minutes=5) == end_time:
                batch.delete_item(Key={'Password': item['Password']})
    print('done')

def main(cmd):
    if cmd == 'scan':
        scan()
    if cmd == 'generate':
        generate()
    if cmd == 'generate_and_write':
        generate(write=True)
    if cmd == 'clear':
        clear()

if __name__ == '__main__':
    main(*sys.argv[1:])
