Class DataPipe.Helper Extends %RegisteredObject
{

ClassMethod SetPythonPath(pClasspaths)
{
    set sys = ##class(%SYS.Python).Import("sys")
    do sys.path.append(pClasspaths)
}

ClassMethod GetPythonInstance(
	pModule,
	pRemoteClassname) As %SYS.Python
{
    set importlib = ##class(%SYS.Python).Import("importlib")
    set builtins = ##class(%SYS.Python).Import("builtins")
    set module = importlib."import_module"(pModule)
    set class = builtins.getattr(module, pRemoteClassname)
    return class."__new__"(class)
}

}
