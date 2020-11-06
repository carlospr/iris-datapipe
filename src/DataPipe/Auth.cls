/// DataPipe Auth methods
/// You can override this methods to use your own roles, resources, etc.
Class DataPipe.Auth Extends %Library.RegisteredObject
{

/// Returns true if User is a DataPipe Administrator
ClassMethod IsAdminUser() As %Library.Boolean
{
	quit $roles["%All"
}

}
