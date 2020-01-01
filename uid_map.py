import sys, json 

items = json.load(sys.stdin)["items"]
for i in items:
    name = i["network_address"].split(".")[0]
    print(name, i["uid"])
