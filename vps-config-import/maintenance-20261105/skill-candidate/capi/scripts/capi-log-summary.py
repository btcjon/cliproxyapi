#!/usr/bin/env python3
"""Summarize log levels and HTTP statuses; discard all original log content."""
import collections,json,re,sys
levels=collections.Counter();statuses=collections.Counter();lines=0
for line in sys.stdin:
 lines+=1
 m=re.search(r"\[(info|warn|warning|error|debug|fatal)\s*\]",line,re.I)
 if m:levels[m.group(1).lower()]+=1
 m=re.search(r"\]\s+([1-5][0-9]{2})\s*\|",line)
 if m:statuses[m.group(1)]+=1
print(json.dumps({"lines":lines,"levels":dict(levels),"http_statuses":dict(statuses)}))
