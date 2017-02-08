import os
import re
import sys
import heapq
import threading
from datetime import datetime, timedelta


class Analyze:
    def __init__(self, path, interval=10):
        self.path = path
        self.cursor = os.path.getsize(path)
        self.event = threading.Event()
        self.interval = interval
        self.first = True
        self.start_time = None
        self.next_time = None
        self.between = None
        self.output_path = "./output.log"
        self.convert = "M"
        self.pattern = re.compile(r'(?P<ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) .* .* '
                             r'\[(?P<time>.*)\] "(?P<method>\w+) (?P<url>\S*)'
                             r' (?P<protocol>[\w/\.]*)" (?P<status>\d{1,3}) (?P<length>\d+) "(?P<referer>.*)" "(?P<ua>.*" .*)')
        self.init_data = {
            "referer": {},
        }

    def color_print(self, msg, color="red"):
        COLOR_DICT = {
            "red": "\033[1;31m{}\033[0m",
            "blue": "\033[1;36m{}\033[0m",
            "green": "\033[1;32m{}\033[0m",
            "yellow": "\033[1;33m{}\033[0m",
        }
        return COLOR_DICT[color].format(msg)

    def read_log(self):
        while not self.event.is_set():
            with open(self.path) as f:
                if self.cursor > os.path.getsize(self.path):
                    self.cursor = 0
                f.seek(self.cursor)
                yield from f
                self.cursor = f.tell()
            self.event.wait(1)

    def parse(self):
        for line in self.read_log():
            m = self.pattern.search(line.rstrip("\n"))
            if m:
                data = m.groupdict()
                data['time'] = datetime.strptime(data['time'], "%d/%b/%Y:%H:%M:%S %z")
                yield data

    def count(self, key, value, data):
        if data[key] not in value.keys():
            value[data[key]] = 0
        value[data[key]] = value[data[key]] + int(data["length"])
        return value

    def date_to_str(self, time):
        return time.strftime('%Y%m%d %H:%M:%S')

    def convert_handle(self, iter):
        CONVERT = {
            "M": 1024*1024,
            "G": 1024*1024*1024
        }
        for i in iter:
            value = round(i[1] / CONVERT.get(self.convert, "M"), 2)
            i[1] = str(value) + "M"
        return iter

    def define_time(self, init_time, ret):
        self.start_time = self.date_to_str(init_time)
        self.next_time = init_time + timedelta(minutes=self.interval)
        self.between = self.start_time + "-" + self.date_to_str(self.next_time)
        ret[self.between] = 0

    def analyze(self):
        ret = {}
        for item in self.parse():
            if self.first:
                self.define_time(item["time"], ret)
                self.first = False
            if item["time"] < self.next_time:
                for key, value in self.init_data.items():
                    self.count(key, value, item)
            else:
                ret[self.between] = self.init_data
                l1 = [[key, value] for key, value in self.init_data["referer"].items()]
                top_ten = heapq.nlargest(10, l1, key=lambda x: x[1])
                between = self.color_print(self.between, "red")
                msg = self.color_print("前10个页面访问量", "blue")
                entry = self.convert_handle(top_ten)
                with open(self.output_path, "a+") as f:
                    f.write("'{}'{}: {}\n".format(between, msg, entry))
                self.init_data = {"referer": {}}
                self.define_time(self.next_time, ret)

if __name__ == '__main__':
    analysis = Analyze(*sys.argv[1:])
    try:
        t = threading.Thread(target=analysis.analyze)
        t.start()
    except KeyboardInterrupt:
        analysis.event.set()
