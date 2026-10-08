extends RefCounted
## Optional Yandex state. Skips unlock levels but are never counted as wins.
static func ensure(data: Dictionary) -> void:
	if data.has("ad_state"): return
	var seen: Array=[]
	for id in data.completed: seen.append("light:"+str(int(id)))
	for id in data.match3.completed: seen.append("match:"+str(int(id)))
	data.ad_state={"seen":seen,"since":0,"pending":false,"skipped":{"light":[],"match":[]},"claims":[]}
static func valid(s: Variant) -> bool:
	if not s is Dictionary or not s.get("seen") is Array or not s.get("claims") is Array or not s.get("skipped") is Dictionary or not s.get("pending") is bool: return false
	if not typeof(s.get("since")) in [TYPE_INT,TYPE_FLOAT] or float(s.since)!=int(s.since) or s.since<0 or s.since>9: return false
	if s.seen.size()>2000 or s.claims.size()>64: return false
	for key in s.seen:
		if not key is String: return false
		var parts: PackedStringArray=key.split(":")
		if parts.size()!=2 or parts[0] not in ["light","match"] or not parts[1].is_valid_int() or int(parts[1])<1 or int(parts[1])>1000: return false
	for token in s.claims:
		if not token is String or token.length()>100: return false
	for mode in ["light","match"]:
		if not s.skipped.get(mode) is Array or s.skipped[mode].size()>1000: return false
		for id in s.skipped[mode]:
			if not typeof(id) in [TYPE_INT,TYPE_FLOAT] or float(id)!=int(id) or id<1 or id>1000: return false
	return true
static func skipped(data: Dictionary,mode: String,id: int) -> bool:
	return id in data.get("ad_state",{}).get("skipped",{}).get(mode,[])
static func won(data: Dictionary,mode: String,id: int) -> bool:
	ensure(data)
	var key:=mode+":"+str(id)
	if key in data.ad_state.seen: return false
	data.ad_state.seen.append(key); data.ad_state.since+=1
	if data.ad_state.since>=10: data.ad_state.since=0; data.ad_state.pending=true
	return true
static func claim(data: Dictionary,token: String,kind: String,mode: String,id: int) -> bool:
	ensure(data)
	if token.is_empty() or token in data.ad_state.claims or kind not in ["coins","hint","skip"]: return false
	if kind=="skip":
		if mode not in ["light","match"] or id<1 or id>1000 or skipped(data,mode,id): return false
		var done: Array=data.completed if mode=="light" else data.match3.completed
		if id in done: return false
		data.ad_state.skipped[mode].append(id)
		if mode=="light": data.current=mini(1000,id+1)
		else: data.match3.current=mini(1000,id+1)
	elif kind=="coins": data.garden.coins+=50
	data.ad_state.claims.append(token)
	if data.ad_state.claims.size()>64: data.ad_state.claims.pop_front()
	return true
