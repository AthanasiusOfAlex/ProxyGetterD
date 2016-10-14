module main;

pragma(lib, "ProxyGetterLibrary");

import std.stdio;
import std.string;
import std.traits;
import std.range;

enum ProxyType {
	
	http,
	https,
	ftp,
	socks,
	no
	
}

private extern (Objective-C)
	interface ClassObjC
{
	NSStringObjC allocNSString() @selector("alloc");
	NSNumberObjC allocNSNumber() @selector("alloc");
}

private extern (Objective-C)
	interface NSStringObjC
{
	NSStringObjC initWithUTF8String(in char* str) @selector("initWithUTF8String:");
	immutable(char)* UTF8String() @selector("UTF8String");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSNumberObjC
{
	NSNumberObjC initWithInt(in int number) @selector("initWithInt:");
	int intValue() @selector("intValue");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSDictionaryObjC
{
	NSStringObjC nsStringForKey(NSStringObjC key) @selector("objectForKey:");
	NSNumberObjC nsNumberForKey(NSStringObjC key) @selector("objectForKey:");
	NSArrayObjC allKeys() @selector("allKeys");
	void release() @selector("release");
}

private extern (Objective-C)
	interface NSArrayObjC
{
	NSStringObjC stringAtIndex(uint index) @selector("objectAtIndex:");
	uint count() @selector("count");
	void release() @selector("release");
}

private extern (C) ClassObjC objc_lookUpClass(in char* name);
private extern (C) NSDictionaryObjC getProxyTable();

/// Wrapper to NSString.
private struct NSString {

private:
	NSStringObjC nsStringObjC;
	@property NSStringObjC objectiveCObject() { return nsStringObjC; }

public:

	/// If you intend for the object to take care of memory
	/// management, set this property to `true`.
	/// If the object is owned by another object, be sure to
	/// set this property to `false`; otherwise, the program
	/// will crash.
	bool isOwner = true;

	@property immutable(char)* toStringz() { return nsStringObjC.UTF8String; }
	@property string toString() { return fromStringz(toStringz).idup; }


	this(string input) {
	
		auto classLookup = objc_lookUpClass("NSString");
		this.nsStringObjC = classLookup.allocNSString().initWithUTF8String(input.toStringz);

	}

	~this() {

		if(isOwner) { this.nsStringObjC.release(); }

	}

}

/// Wrapper to NSNumber.
private struct NSNumber {
	
private:

	NSNumberObjC nsNumberObjC;
	@property NSNumberObjC objectiveCObject() { return nsNumberObjC; }
	
public:

	/// If you intend for the object to take care of memory
	/// management, set this property to `true` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `false`; otherwise, the program
	/// will crash.
	bool isOwner = true;

	@property int toInt() { return nsNumberObjC.intValue; }
	@property uint toUInt() { return nsNumberObjC.intValue; }

	this(uint input) {
		
		auto classLookup = objc_lookUpClass("NSNumber");
		this.nsNumberObjC = classLookup.allocNSNumber().initWithInt(input);
		
	}

	this(NSNumberObjC objectiveCObject) {

		this.nsNumberObjC = objectiveCObject;

	}
	
	~this() {
		
		if(isOwner) { this.nsNumberObjC.release(); }
		
	}
	
}

/// Wrapper to NSDictionary.
private class NSDictionary {
	
private:
	NSDictionaryObjC nsDictionaryObjC;
	@property NSDictionaryObjC objectiveCObject() { return nsDictionaryObjC; }
	@property NSArray allKeys() { return new NSArray(nsDictionaryObjC.allKeys); }

public:

	/// If you intend for the object to take care of memory
	/// management, set this property to `true` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `false`; otherwise, the program
	/// will crash.
	bool isOwner = true;

	T getValue(T)(string key)
		if(is(T==int) || is(T==string))
	{

		auto nsKey = NSString(key);

		// Now, simply extract the value and convert to a D type.
		static if(is(T==int)) {

			// NB: The following as an NSNumber that is "owned" by the dictionary,
			// so don't try to release it.
			auto valueObjC = nsDictionaryObjC.nsNumberForKey(nsKey.objectiveCObject);
			auto value = valueObjC.intValue;

		} else static if(is(T==string)) {

			// NB: The following as an NSString that is "owned" by the dictionary,
			// so don't try to release it.
			auto valueObjC = nsDictionaryObjC.nsStringForKey(nsKey.objectiveCObject);auto valueC = valueObjC.UTF8String;
			auto value = fromStringz(valueC).idup;

		} else {

			assert(false, "The type should be int or string.");

		}

		return value;

	}

	this(NSDictionaryObjC nsDictionaryObjC) {
		
		this.nsDictionaryObjC = nsDictionaryObjC;

	}

	~this() {

		if(isOwner) { nsDictionaryObjC.release(); }

	}
	
}

/// Simplified wrapper to NSArray.
private class NSArray {

private:
	NSArrayObjC nsArrayObjC;
	@property NSArrayObjC objectiveCObject() { return nsArrayObjC; }
	uint currentIndex = 0;

public:

	// The following makes NSArray a forward range.
	@property bool empty() { return count - currentIndex <= 0; }
	@property string front() { return this[currentIndex]; }
	@property void popFront() { ++currentIndex; }

	string opIndex(int index) {

		NSStringObjC nsStringObjC = nsArrayObjC.stringAtIndex(currentIndex);
		auto cString = nsStringObjC.UTF8String;
		auto value = fromStringz(cString).idup;

		return value;

	}

	/// If you intend for the object to take care of memory
	/// management, set this property to `true` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `false`; otherwise, the program
	/// will crash.
	bool isOwner = true;

	@property int count() { return nsArrayObjC.count; }

	this(NSArrayObjC objectiveCObject) {

		nsArrayObjC = objectiveCObject;

	}

	~this() {

		if(isOwner) { nsArrayObjC.release(); }

	}

}

void main(string[] args)
{

	import std.typecons;

	auto nsProxies = new NSDictionary(getProxyTable());


	foreach(key; nsProxies.allKeys) {

		writeln(key);

	}


	writeln(nsProxies.getValue!string("HTTPProxy"), nsProxies.getValue!int("HTTPPort"), nsProxies.getValue!int("HTTPEnable"));

}

