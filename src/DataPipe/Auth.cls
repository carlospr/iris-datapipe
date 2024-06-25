/// DataPipe Auth methods
/// You can override this methods to use your own roles, resources, etc.
Class DataPipe.Auth Extends %Library.RegisteredObject
{

/// Returns fullname of User
ClassMethod GetFullName() As %String
{
	set fullName = ""
	new $namespace
	set $namespace = "%SYS"
	$$$ThrowOnError(##class(Security.Users).Get($username, .properties))
	
	if properties("FullName")="" {
		return $username
	} else {
		return properties("FullName")
	}
}

/// Returns a object containing all datapipe permissions (IRIS resources)
/// 
/// Resources will be like:
/// DP_ADMIN:U
/// DP_MENU_DASHBOARD:RU
/// DP_MENU_SEARCH:R
/// DP_MENU_DATA:RW
/// DP_MENU_AUDIT:R
/// DP_MENU_ABOUT:R
/// DP_PIPE_VACCINES:RWU
/// DP_PIPE_AFLOW:R
/// DP_PIPE_DEMO:RW
ClassMethod GetPermissions() As %DynamicObject
{
	new $namespace
	set $namespace = "%SYS"

	set jsonObj = {}

	set sc = ##class(Security.Users).GetResourceSet($username,,.resources)
	set resources = $listfromstring(resources)

	for i=1:1:$listlength(resources) {
		set res = $listget(resources, i)
		set resName = $piece(res,":",1)
		set resAccessLevel = $piece(res,":",2)

		if resName [ "DP_" {
			do jsonObj.%Set(resName, resAccessLevel)
		}
	}

	return jsonObj
}

}
