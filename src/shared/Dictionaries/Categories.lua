local Categories = {}

Categories = {
	Core = "Core",
	Drill = "Drill",
	Factory = "Factory",
	Storage = "Storage",
	["Power Generator"] = "Power Generator",
	Battery = "Battery",
	["Power Node"] = "Power Node",
	["Extra Module"] = "Extra Module",
	["Unit Factory"] = "Unit Factory",
	Unit = "Unit",
	Turret = "Turret",
	Wall = "Wall",
	["Building Mender"] = "Building Mender",
	["Unit Mender"] = "Unit Mender",
}

-- Build menu display order per category
Categories.Order = {
	[Categories.Core]               = 1,
	[Categories.Drill]              = 2,
	[Categories.Factory]            = 3,
	[Categories.Storage]            = 4,
	[Categories["Power Generator"]] = 5,
	[Categories.Battery]            = 6,
	[Categories["Power Node"]]      = 7,
	[Categories["Extra Module"]]    = 8,
	[Categories["Unit Factory"]]    = 9,
	[Categories.Unit]               = 10,
	[Categories.Turret]             = 11,
	[Categories.Wall]               = 12,
	[Categories["Building Mender"]] = 13,
	[Categories["Unit Mender"]]     = 14,
}

return Categories
