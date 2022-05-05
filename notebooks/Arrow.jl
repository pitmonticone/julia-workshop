### A Pluto.jl notebook ###
# v0.19.0

using Markdown
using InteractiveUtils

# ╔═╡ 146dfffc-5f58-11eb-3053-d31ada3a5428
using Arrow, DataFrames, PyCall, RCall

# ╔═╡ 6d417df8-5f48-11eb-1afa-4f148f2f3121
md"""
# Arrow for data saving and transfer

The [Apache Arrow format](https://arrow.apache.org/) is a binary format for column-oriented tabular data.
It is supported by packages for several languages, including `R` and `Python`.

The Julia implementation, https://github.com/JuliaData/Arrow.jl, is unusual in that it is a native implementation and does not rely on the underlying C++ library used by other implementations.

In Julia Arrow is primarily used for saving and restoring data Tables and for exchanging data tables with `R` and `Python`.

### Reading an Arrow table written from Julia

Recall that in the `consistency.jl` notebook the manybabies data were written to files `02_validated_output.arrow` and `02_validated_output_compressed.arrow`
"""

# ╔═╡ c12b82c2-60ee-11eb-3b0a-81dbbc109227
md"""
The `Arrow.Table` function reads an arrow file and returns a columnar table, which can be converted to a `DataFrame` if desired.
An uncompressed arrow file is memory-mapped so reading even a very large arrow file is fast.
"""

# ╔═╡ 7340991a-5f5b-11eb-310f-594dcc07c68c
tbl = Arrow.Table("02_validated_output.arrow")

# ╔═╡ 9de89dfc-5f5b-11eb-3bf8-7325d9ceb526
begin
	df = DataFrame(tbl)
	describe(df)
end

# ╔═╡ 5c22c946-5f5c-11eb-2003-43080004e3a1
md"""
This is essentially the same table as was written.
The values in the columns are the same as in the original table.
The column types are sometimes different from but equivalent to the original columns.
"""

# ╔═╡ bf5c2c78-5f5c-11eb-0e66-51750c12c3f0
typeof(tbl.subid)

# ╔═╡ d84387a4-5f5c-11eb-315a-0fcf3bcc650f
md"""
Reading from the compressed arrow file is similar but takes a bit longer because the file must be uncompressed when reading.
"""

# ╔═╡ 02a6cee8-5f5d-11eb-2b82-0305f32de39f
tbl2 = Arrow.Table("02_validated_output_compressed.arrow")

# ╔═╡ a0d348fc-5f59-11eb-1610-33cc30f74060
md"""
### Reading an Arrow table written with R

Suppose we wish to access the `palmerpenguins::penguins` data set from `R`.

We will use some functions from the `RCall` package without much explanation.
Suffice it to say that prepending a quoted string with `R` causes it to be evaluated in an R instance.
If the string contains quote characters it should be wrapped in triple quotes.
"""

# ╔═╡ 304dbd5c-5f58-11eb-3f93-d768a48487d5
R"library(arrow)";

# ╔═╡ 4dfc17e0-5f58-11eb-187a-17f3b589e22a
R"""write_feather(palmerpenguins::penguins, "penguins.arrow")"""

# ╔═╡ 7813ebb6-5f58-11eb-3d10-affbe5c1c60b
md"""
The [`palmerpenguins` package](https://allisonhorst.github.io/palmerpenguins/) contains this table.
The `arrow` package for R and the `pyarrow` Python package both refer to the arrow file format as `feather`.
Feather was an earlier file format and the arrow format is now considered version 2 of Feather.
This is just to explain why these packages use names like `write_feather`.

Now read this file as a table in Julia.
"""

# ╔═╡ 2c82a0c6-5f5a-11eb-0132-f7584460d831
penguins = DataFrame(Arrow.Table("penguins.arrow"))

# ╔═╡ 6e08e19a-5f5a-11eb-33aa-21a284ece05b
describe(penguins)

# ╔═╡ 022743a2-5f5e-11eb-0477-cf77576fdc77
md"""
Notice that all the columns allow for missing data, even when there are no missing values in the column.
This is always the case in `R`.

Also, the numeric types will always be `Int32` or `Float64` and most data tables will contain only these types plus `String`.


That is not a problem coming from R to Julia - at most it is an inconvenience.

To read this in Python we use the `pyarrow` package through the already loaded `PyCall` package for Julia
(note that if you install `pyarrow` using `conda` it is important to specify `-c conda-forge` - otherwise you will get a badly out-of-date version).
"""

# ╔═╡ 344e105a-6011-11eb-1247-c79e874ad0e6
feather = pyimport("pyarrow.feather");

# ╔═╡ 4c560c66-6011-11eb-23dd-e575a7449301
fr = feather.read_feather("penguins.arrow")

# ╔═╡ 1d57f6b8-60f4-11eb-3b0d-3f0a7cca045f
md"""
A more basic method, `feather.read_table`, produces a `pyarrow.Table`.
In fact, `read_feather` simply calls `read_table` then converts the result to a pandas dataframe.
Occasionally there are problems in the conversion so it is good to know about `read_table`.
"""

# ╔═╡ 8e975c6a-6011-11eb-2843-d5991dabe7c1
feather.read_table("penguins.arrow")   # produces a pyarrow.Table

# ╔═╡ e934fc9a-6011-11eb-1f93-a37558c1d2a9
md"""
## Reading an Arrow file from Julia in R or Python

Recent additions to the `arrow` package for R and the `pyarrow` package for Python have greatly expanded the flexibility of these packages.
"""

# ╔═╡ 487d7b38-60f5-11eb-0162-6391d5b99b89
R"library(tibble)";

# ╔═╡ 540279a6-60f5-11eb-39b7-ff25a8dad69e
R"""valid <- read_feather("02_validated_output.arrow"); glimpse(valid)"""

# ╔═╡ 9f6a025e-60f5-11eb-2e89-052cce54dcd1
md"""
It is not obvious but there are some conversions necessary to read a general arrow file and create an R `data.frame` or `tibble`.

To see the form as stored in the arrow file it is convenient to use Python's `pyarrow.Table`.
"""

# ╔═╡ ccd2caee-6013-11eb-3514-211c3a140eec
feather.read_table("02_validated_output.arrow")

# ╔═╡ bf9a6a60-60f6-11eb-1d60-5d2749b801c8
md"""
Several columns, such as `trial_num` and `stimulus_num` are returned as the default integer type, `Int64`, from `CSV.File` and these need to be converted to `Int32` in R.
"""

# ╔═╡ 165e118a-60f7-11eb-2ee4-5fc34fdb0413
R"class(valid$trial_num)"

# ╔═╡ 2eec5644-60f7-11eb-2b0e-e91b3a5d397e
R"""write_feather(valid, "02_validated_from_R.arrow")""";

# ╔═╡ 5c0fed50-60f7-11eb-3840-b7bb6567c414
feather.read_table("02_validated_from_R.arrow")

# ╔═╡ 0345cd9c-625b-11eb-08a4-2f0eb3598a02
md"""
Note that there are two changes in some columns: those that were `int64` are now `int32` and there are no columns marked `not null`.
That is, all columns now allow for missing data.

In Julia we can check with
"""

# ╔═╡ 6c29d874-60f7-11eb-2f28-7b024614b47f
Tables.schema(Arrow.Table("02_validated_from_R.arrow"))

# ╔═╡ 326357e0-60f8-11eb-1243-a11b01c54c93
md"""
## Conversion from Int64 vectors to smaller integer types

The `Int64` or `Union{Missing,Int64}` columns in the table, `tbl`, are coded as such because the default integer type, `Int`, is equivalent to `Int64` on a 64-bit implementation of Julia.

It is possible to specify the types of the columns in the call to `CSV.File` when reading the original CSV file but doing so requires knowing the contents of the columns before reading the file.  It is usually easier to read the file with the inferred types then change later.

First, check which columns have element types of `Int64` or `Union{Missing,Int64}`.
For this it helps to use `nonmissingtype` to produce the underlying type from a column that allows for missing data.
"""

# ╔═╡ 8ce3d320-6198-11eb-0c8b-9f89171ca4eb
let et = eltype(df.trial_num)
	et, nonmissingtype(et)
end

# ╔═╡ a612a74a-6198-11eb-03e2-61dc1f6b2d91
let et = eltype(df.stimulus_num)
	et, nonmissingtype(et)
end

# ╔═╡ cde9956c-6198-11eb-3ecf-d5b20a829eb7
md"""
Now we want to examine all the columns to find those whose nonmissing eltype is `Int64`.

For a dataframe `df` the `eachcol` function returns an iterator over the columns.  Wrapping this in `pairs` produces an iterator of `name, value` pairs which we can use to discover which columns are coded as `Int64`, with or without missing values.
"""

# ╔═╡ c640e170-6199-11eb-2b53-59932c869eeb
begin
	intcols = Symbol[]
	for (n,v) in pairs(eachcol(df))
		Int64 == nonmissingtype(eltype(v)) && push!(intcols, n)
	end
	intcols
end

# ╔═╡ 4f0d6f46-619a-11eb-3885-3b274bf30cd0
md"""
For each of these columns we determine the extrema (minimum and maximum), using `skipmissing` to avoid the missing values, then compare against the `typemin` and `typemax` for various integer types to determine the smallest type of integer that can encode the data.
"""

# ╔═╡ fce28458-619a-11eb-2a0d-a90f00f1d7b8
function inttype(x)
	mn, mx = extrema(skipmissing(x))
	if typemin(Int8) ≤ mn ≤ mx ≤ typemax(Int8)
		Int8
	elseif typemin(Int16) ≤ mn ≤ mx ≤ typemax(Int16)
		Int16
	elseif typemin(Int32) ≤ mn ≤ mx ≤ typemax(Int32)
		Int32
	else
		Int64
	end
end

# ╔═╡ bc14c3c6-61ba-11eb-0713-8b0102504a75
conv = map(sym -> Pair(sym, inttype(getproperty(df, sym))), intcols)

# ╔═╡ 2f15c8a6-61bc-11eb-33b5-dbbec9adc3e6
for pr in conv
	setproperty!(df, first(pr), passmissing(last(pr)).(getproperty(df, first(pr))))
end

# ╔═╡ 09d16a40-61bd-11eb-0a01-116e5ef1e1c4
Tables.schema(df)

# ╔═╡ 436a2e7c-61bd-11eb-1fbf-1f3dc862f710
md"""
Finally we write a new Arrow file.
"""

# ╔═╡ 9200d74a-625b-11eb-3a39-21b57ab3fc4b
Arrow.write("02_compact.arrow", df, compress=:zstd);

# ╔═╡ be25db36-625b-11eb-2033-cb284fffd5b8
filesize("02_compact.arrow")

# ╔═╡ 03108a5c-625c-11eb-1add-2ff36f5d4bdb
feather.read_table("02_compact.arrow")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Arrow = "69666777-d1a9-59fb-9406-91d4454c9d45"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
RCall = "6f49c342-dc21-5d91-9882-a32aef131414"

[compat]
Arrow = "~2.3.0"
DataFrames = "~1.3.2"
PyCall = "~1.93.1"
RCall = "~0.13.13"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Arrow]]
deps = ["ArrowTypes", "BitIntegers", "CodecLz4", "CodecZstd", "DataAPI", "Dates", "Mmap", "PooledArrays", "SentinelArrays", "Tables", "TimeZones", "UUIDs"]
git-tree-sha1 = "4e7aa2021204bd9456ad3e87372237e84ee2c3c1"
uuid = "69666777-d1a9-59fb-9406-91d4454c9d45"
version = "2.3.0"

[[deps.ArrowTypes]]
deps = ["UUIDs"]
git-tree-sha1 = "a0633b6d6efabf3f76dacd6eb1b3ec6c42ab0552"
uuid = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
version = "1.2.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitIntegers]]
deps = ["Random"]
git-tree-sha1 = "5a814467bda636f3dde5c4ef83c30dd0a19928e0"
uuid = "c3b6d118-76ef-56ca-8cc7-ebb389d030a1"
version = "0.2.6"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.CategoricalArrays]]
deps = ["DataAPI", "Future", "Missings", "Printf", "Requires", "Statistics", "Unicode"]
git-tree-sha1 = "109664d3a6f2202b1225478335ea8fea3cd8706b"
uuid = "324d7699-5711-5eae-9e2f-1d82baa6b597"
version = "0.10.5"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9950387274246d08af38f6eef8cb5480862a435f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.14.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.CodecLz4]]
deps = ["Lz4_jll", "TranscodingStreams"]
git-tree-sha1 = "59fe0cb37784288d6b9f1baebddbf75457395d40"
uuid = "5ba52731-8f18-5e0d-9241-30f10d1ec561"
version = "0.4.0"

[[deps.CodecZstd]]
deps = ["CEnum", "TranscodingStreams", "Zstd_jll"]
git-tree-sha1 = "849470b337d0fa8449c21061de922386f32949d9"
uuid = "6b39b394-51ab-5f42-8807-6242bab2b4c2"
version = "0.7.2"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "b153278a25dd42c65abbf4e62344f9d22e59191b"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.43.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "6e47d11ea2776bc5627421d59cdcc1296c058071"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.7.0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "ae02104e835f219b8930c7664b8012c93475c340"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.2"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.ExprTools]]
git-tree-sha1 = "56559bbef6ca5ea0c0818fa5c90320398a6fbf8d"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.8"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "61feba885fac3a407465726d0c330b3055df897f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.1.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "91b5dcf362c5add98049e6c29ee756910b03051d"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.3"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a970d55c2ad8084ca317a4658ba6ce99b7523571"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.12"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Lz4_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "5d494bc6e85c4c9b626ee0cab05daa4085486ab1"
uuid = "5ced341a-0733-55b8-9ab6-a4889d929147"
version = "1.9.3+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.Mocking]]
deps = ["Compat", "ExprTools"]
git-tree-sha1 = "29714d0a7a8083bba8427a4fbfb00a540c681ce7"
uuid = "78c3b35d-d492-501b-9361-3d52fe80e533"
version = "0.7.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "621f4f3b4977325b9128d5fae7a8b4829a0c2222"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.4"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "28ef6c7ce353f0b35d0df0d5930e0d072c1f5b9b"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "d3538e7f8a790dc8903519090857ef8e1283eecd"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.5"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.PyCall]]
deps = ["Conda", "Dates", "Libdl", "LinearAlgebra", "MacroTools", "Serialization", "VersionParsing"]
git-tree-sha1 = "1fc929f47d7c151c839c5fc1375929766fb8edcc"
uuid = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
version = "1.93.1"

[[deps.RCall]]
deps = ["CategoricalArrays", "Conda", "DataFrames", "DataStructures", "Dates", "Libdl", "Missings", "REPL", "Random", "Requires", "StatsModels", "WinReg"]
git-tree-sha1 = "72fddd643785ec1f36581cbc3d288529b96e99a7"
uuid = "6f49c342-dc21-5d91-9882-a32aef131414"
version = "0.13.13"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "6a2f7d70512d205ca8c7ee31bfa9f142fe74310c"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.12"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShiftedArrays]]
git-tree-sha1 = "22395afdcf37d6709a5a0766cc4a5ca52cb85ea0"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "1.0.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5ba658aeecaaf96923dce0da9e703bd1fe7666f9"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "8d7530a38dbd2c397be7ddd01a424e4f411dcc41"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.2"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8977b17906b0a1cc74ab2e3a05faa16cf08a8291"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.16"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5950925ff997ed6fb3e985dcce8eb1ba42a0bbe7"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.18"

[[deps.StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "03c99c7ef267c8526953cafe3c4239656693b8ab"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.29"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TimeZones]]
deps = ["Dates", "Downloads", "InlineStrings", "LazyArtifacts", "Mocking", "Printf", "RecipesBase", "Serialization", "Unicode"]
git-tree-sha1 = "0a359b0ee27e4fbc90d9b3da1f48ddc6f98a0c9e"
uuid = "f269a46b-ccf7-5d73-abea-4c690281aa53"
version = "1.7.3"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VersionParsing]]
git-tree-sha1 = "58d6e80b4ee071f5efd07fda82cb9fbe17200868"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.3.0"

[[deps.WinReg]]
deps = ["Test"]
git-tree-sha1 = "808380e0a0483e134081cc54150be4177959b5f4"
uuid = "1b915085-20d7-51cf-bf83-8f477d6f5128"
version = "0.3.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╟─6d417df8-5f48-11eb-1afa-4f148f2f3121
# ╠═146dfffc-5f58-11eb-3053-d31ada3a5428
# ╟─c12b82c2-60ee-11eb-3b0a-81dbbc109227
# ╠═7340991a-5f5b-11eb-310f-594dcc07c68c
# ╠═9de89dfc-5f5b-11eb-3bf8-7325d9ceb526
# ╟─5c22c946-5f5c-11eb-2003-43080004e3a1
# ╠═bf5c2c78-5f5c-11eb-0e66-51750c12c3f0
# ╟─d84387a4-5f5c-11eb-315a-0fcf3bcc650f
# ╠═02a6cee8-5f5d-11eb-2b82-0305f32de39f
# ╟─a0d348fc-5f59-11eb-1610-33cc30f74060
# ╠═304dbd5c-5f58-11eb-3f93-d768a48487d5
# ╠═4dfc17e0-5f58-11eb-187a-17f3b589e22a
# ╟─7813ebb6-5f58-11eb-3d10-affbe5c1c60b
# ╠═2c82a0c6-5f5a-11eb-0132-f7584460d831
# ╠═6e08e19a-5f5a-11eb-33aa-21a284ece05b
# ╟─022743a2-5f5e-11eb-0477-cf77576fdc77
# ╠═344e105a-6011-11eb-1247-c79e874ad0e6
# ╠═4c560c66-6011-11eb-23dd-e575a7449301
# ╟─1d57f6b8-60f4-11eb-3b0d-3f0a7cca045f
# ╠═8e975c6a-6011-11eb-2843-d5991dabe7c1
# ╟─e934fc9a-6011-11eb-1f93-a37558c1d2a9
# ╠═487d7b38-60f5-11eb-0162-6391d5b99b89
# ╠═540279a6-60f5-11eb-39b7-ff25a8dad69e
# ╟─9f6a025e-60f5-11eb-2e89-052cce54dcd1
# ╠═ccd2caee-6013-11eb-3514-211c3a140eec
# ╟─bf9a6a60-60f6-11eb-1d60-5d2749b801c8
# ╠═165e118a-60f7-11eb-2ee4-5fc34fdb0413
# ╠═2eec5644-60f7-11eb-2b0e-e91b3a5d397e
# ╠═5c0fed50-60f7-11eb-3840-b7bb6567c414
# ╟─0345cd9c-625b-11eb-08a4-2f0eb3598a02
# ╠═6c29d874-60f7-11eb-2f28-7b024614b47f
# ╟─326357e0-60f8-11eb-1243-a11b01c54c93
# ╠═8ce3d320-6198-11eb-0c8b-9f89171ca4eb
# ╠═a612a74a-6198-11eb-03e2-61dc1f6b2d91
# ╟─cde9956c-6198-11eb-3ecf-d5b20a829eb7
# ╠═c640e170-6199-11eb-2b53-59932c869eeb
# ╟─4f0d6f46-619a-11eb-3885-3b274bf30cd0
# ╠═fce28458-619a-11eb-2a0d-a90f00f1d7b8
# ╠═bc14c3c6-61ba-11eb-0713-8b0102504a75
# ╠═2f15c8a6-61bc-11eb-33b5-dbbec9adc3e6
# ╠═09d16a40-61bd-11eb-0a01-116e5ef1e1c4
# ╟─436a2e7c-61bd-11eb-1fbf-1f3dc862f710
# ╠═9200d74a-625b-11eb-3a39-21b57ab3fc4b
# ╠═be25db36-625b-11eb-2033-cb284fffd5b8
# ╠═03108a5c-625c-11eb-1add-2ff36f5d4bdb
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
