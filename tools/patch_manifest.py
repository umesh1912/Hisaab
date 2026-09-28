"""Sets the app label and adds UPI / web intent queries to a freshly created Flutter Android manifest."""
import re
import sys

path, label = sys.argv[1], sys.argv[2]
s = open(path, encoding="utf-8").read()
s = re.sub(r'android:label="[^"]*"', f'android:label="{label}"', s, count=1)

queries = """
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="upi" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
"""
if 'android:scheme="upi"' not in s:
    if "<queries>" in s:
        s = s.replace("<queries>", queries.strip()[len("<queries>"):].rsplit("</queries>", 1)[0].join(["<queries>", ""]), 1)
    else:
        s = s.replace("</manifest>", queries + "</manifest>", 1)
open(path, "w", encoding="utf-8").write(s)
print(f"patched {path} label={label}")
