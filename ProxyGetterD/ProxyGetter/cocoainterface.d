module ProxyGetter.CocoaInterface;

import std.string;

enum OwnerStatus {

	isOwner,
	isNotOwner
	
}

enum ProxyType {
	
	http,
	https,
	ftp,
	socks,
	
} 

/*********************************************
 * Declarations of Objective C interfaces.
 *********************************************/
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

/*********************************************
 * Declarations of Cocoa functions and types
 * needed for the internals of the wrappers.
 * These should not be visible externally.
 *********************************************/

// Types

private extern (C) struct objc_class;
private alias Class = objc_class*;
private extern (C) struct objc_object {
	Class isa;
};
private alias id = objc_object*;

private extern (C) struct __CFAllocator;
private alias CFAllocatorRef = __CFAllocator*;

private extern (C) struct __CFString;
private alias CFStringRef =  __CFString*;

private alias CFStringEncoding = uint;
private enum CFStringEncoding kCFStringEncodingUTF8 = 0x08000100;

private alias CFTypeRef = void*;
private extern (C) void CFRelease(CFTypeRef cf);

private extern (C) struct  __SCDynamicStore;
private alias SCDynamicStoreRef = __SCDynamicStore*;
private alias SCDynamicStoreCallBack = void*;
private extern (C) struct SCDynamicStoreContext;

private extern (C) struct __CFDictionary;
private alias CFDictionaryRef = __CFDictionary*;

private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPProxy;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPSProxy;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesFTPProxy;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesSOCKSProxy;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPPort;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPSPort;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesFTPPort;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesSOCKSPort;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPEnable;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesHTTPSEnable;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesFTPEnable;
private extern (C) extern __gshared immutable CFStringRef kSCPropNetProxiesSOCKSEnable;

// Extensions to help use some of the Objective C types.

private string toString(const CFStringRef cfString) {

	auto cString = CFStringGetCStringPtr(cfString, kCFStringEncodingUTF8);

	if (cString == null) {

		return "";

	} else {

		return cString.fromStringz.idup;

	}

}

struct ProxyDictionaryKeys {

	string proxy;
	string port;
	string enable;
}

ProxyDictionaryKeys getKeys(ProxyType proxyType) {

	ProxyDictionaryKeys result;

	switch(proxyType) {

		case ProxyType.http:
			result = ProxyDictionaryKeys(
				kSCPropNetProxiesHTTPProxy.toString,
				kSCPropNetProxiesHTTPPort.toString,
				kSCPropNetProxiesHTTPEnable.toString);
			break;

		case ProxyType.https:
			result = ProxyDictionaryKeys(
				kSCPropNetProxiesHTTPSProxy.toString,
				kSCPropNetProxiesHTTPSPort.toString,
				kSCPropNetProxiesHTTPSEnable.toString);
			break;

		case ProxyType.ftp:
			result = ProxyDictionaryKeys(
				kSCPropNetProxiesFTPProxy.toString,
				kSCPropNetProxiesFTPPort.toString,
				kSCPropNetProxiesFTPEnable.toString);
			break;

		case ProxyType.socks:
			result = ProxyDictionaryKeys(
				kSCPropNetProxiesSOCKSProxy.toString,
				kSCPropNetProxiesSOCKSPort.toString,
				kSCPropNetProxiesSOCKSEnable.toString);
			break;

		default:
			assert(0);

	}

	return result;

}

// Functions

private extern (C) ClassObjC objc_lookUpClass(in char* name);

private extern (C) CFStringRef CFStringCreateWithCString(
	CFAllocatorRef alloc,
	immutable(char) *cStr,
	CFStringEncoding encoding);

private extern (C) char* CFStringGetCStringPtr(const CFStringRef theString, CFStringEncoding encoding);

private extern (C) SCDynamicStoreRef SCDynamicStoreCreate(
	CFAllocatorRef allocator,
	CFStringRef name,
	SCDynamicStoreCallBack callout,
	SCDynamicStoreContext * context
	);

private extern (C) CFDictionaryRef SCDynamicStoreCopyProxies (SCDynamicStoreRef store);

/*********************************************
 * Wrappers for Cocoa classes.
 * This is the only publicly available API.
 *********************************************/

/// Wrapper to NSString.
struct NSString {
	
private:
	NSStringObjC nsStringObjC;
	@property NSStringObjC objectiveCObject() { return nsStringObjC; }
	
	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner`.
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the	///program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;
	
public:
	
	@property immutable(char)* toStringz() { return nsStringObjC.UTF8String; }
	@property string toString() { return fromStringz(toStringz).idup; }
	
	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSStringObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {
		
		this.ownerStatus = ownerStatus;
		nsStringObjC = objectiveCObject;
		
	}
	
	this(string input) {
		
		auto classLookup = objc_lookUpClass("NSString");
		this.nsStringObjC = classLookup.allocNSString().initWithUTF8String(input.toStringz);
		
	}
	
	~this() {
		
		if(ownerStatus == OwnerStatus.isOwner) { this.nsStringObjC.release(); }
		
	}
	
}

/// Wrapper for NSNumber.
struct NSNumber {
	
private:
	
	NSNumberObjC nsNumberObjC;
	@property NSNumberObjC objectiveCObject() { return nsNumberObjC; }
	
	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the	///program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;
	
public:
	
	@property int toInt() { return nsNumberObjC.intValue; }
	@property uint toUInt() { return nsNumberObjC.intValue; }
	
	this(uint input) {
		
		auto classLookup = objc_lookUpClass("NSNumber");
		this.nsNumberObjC = classLookup.allocNSNumber().initWithInt(input);
		
	}
	
	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSNumberObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {
		
		this.ownerStatus = ownerStatus;
		this.nsNumberObjC = objectiveCObject;
		
	}
	
	~this() {
		
		if(ownerStatus == OwnerStatus.isOwner) { this.nsNumberObjC.release(); }
		
	}
	
}

/// Wrapper for NSDictionary.
struct NSDictionary {
	
private:
	NSDictionaryObjC nsDictionaryObjC;
	@property NSDictionaryObjC objectiveCObject() { return nsDictionaryObjC; }
	@property NSArray allKeys() { return NSArray(nsDictionaryObjC.allKeys); }
	
	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the
	/// program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;
	
public:
	
	T getValue(T)(string key)
		if(is(T==int) || is(T==string))
	{
		
		auto nsKey = NSString(key);
		
		// Now, simply extract the value and convert to a D type.
		static if(is(T==int)) {
			
			// NB: The following is an NSNumber that is "owned" by the dictionary,
			// so don't try to manage the memory.
			auto nsValue = NSNumber(nsDictionaryObjC.nsNumberForKey(nsKey.objectiveCObject), OwnerStatus.isNotOwner);
			auto value = nsValue.toInt;
			
		} else static if(is(T==string)) {
			
			// NB: The following is an NSString that is "owned" by the dictionary,
			// so don't try to manage the memory.
			auto nsValue = NSString(nsDictionaryObjC.nsStringForKey(nsKey.objectiveCObject), OwnerStatus.isNotOwner);
			auto value = nsValue.toString;
			
		} else {
			
			assert(false, "The type should be int or string.");
			
		}
		
		return value;
		
	}
	
	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSDictionaryObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {
		
		this.ownerStatus = ownerStatus;
		this.nsDictionaryObjC = objectiveCObject;
		
	}
	
	~this() {
		
		if(ownerStatus == OwnerStatus.isOwner) { nsDictionaryObjC.release(); }
		
	}
	
}

/// Wrapper for NSArray.
struct NSArray {
	
private:
	
	NSArrayObjC nsArrayObjC;
	@property NSArrayObjC objectiveCObject() { return nsArrayObjC; }
	uint currentIndex = 0;
	
	/// If you intend for the object to take care of memory
	/// management, set this property to `OwnerStatus.isOwner` (the default).
	/// If the object is owned by another object, be sure to
	/// set this property to `OwnerStatus.isNotOwner`; otherwise, the
	/// program will crash.
	OwnerStatus ownerStatus = OwnerStatus.isOwner;
	
public:
	
	// The following makes NSArray a forward range.
	@property bool empty() { return count - currentIndex <= 0; }
	@property string front() { return this[currentIndex]; }
	@property void popFront() { ++currentIndex; }
	
	string opIndex(int index) {
		
		NSString value = NSString(nsArrayObjC.stringAtIndex(currentIndex), OwnerStatus.isNotOwner);
		return value.toString;
		
	}
	
	@property int count() { return nsArrayObjC.count; }
	
	/// Since this initializer just accepts an
	/// Objective-C pointer, we provide a way to
	/// tell the object not to manage the memory.
	/// Memory is managed by default; set the second
	/// argument to `OwnerStatus.isNotOwner` to
	/// turn this off.
	private this(NSArrayObjC objectiveCObject, OwnerStatus ownerStatus = OwnerStatus.isOwner) {
		
		this.ownerStatus = ownerStatus;
		nsArrayObjC = objectiveCObject;
		
	}
	
	~this() {
		
		if(ownerStatus == OwnerStatus.isOwner) { nsArrayObjC.release(); }
		
	}
	
}

/// Get the proxy settings
NSDictionary getProxySettingsDictionary() {

	auto objectiveCObject = cast(NSDictionaryObjC)SCDynamicStoreCopyProxies(null);
	return NSDictionary(objectiveCObject);

}