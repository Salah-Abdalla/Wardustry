local Categories = {}

Categories = {
	Core = "Core",
	Drill = "Drill",
	Transport = "Transport",
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
	[Categories.Core] = 1,
	[Categories.Transport] = 2,
	[Categories.Drill] = 3,
	[Categories.Factory] = 4,
	[Categories.Storage] = 5,
	[Categories["Power Generator"]] = 6,
	[Categories.Battery] = 7,
	[Categories["Power Node"]] = 8,
	[Categories["Extra Module"]] = 9,
	[Categories["Unit Factory"]] = 10,
	[Categories.Unit] = 11,
	[Categories.Turret] = 12,
	[Categories.Wall] = 13,
	[Categories["Building Mender"]] = 14,
	[Categories["Unit Mender"]] = 15,
}

return Categories
