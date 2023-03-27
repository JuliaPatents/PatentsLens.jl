# PatentsLens.jl
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliapatents.github.io/PatentsLens.jl/dev/)

*Julia package for handling Lens.org patent data.*

## Installation

### Adding the registry

All packages in the JuliaPatents family are registered in the [JuliaPatents registry](https://github.com/JuliaPatents/Registry).
To add the registry, enter the julia REPL and run:

```julia 
using Pkg
pkg"registry add https://github.com/JuliaPatents/Registry"
``` 

This only needs to be done once.

### Adding the package

After adding the registry, the package can be added to any Julia environment:

```julia
using Pkg
pkg"add PatentsLens"
```

The package can now be loaded:

```julia
using PatentsBase, PatentsLens
```

### Optional analysis interface

PatentsLens.jl implements the analysis interface defined by [PatentsLandscapes.jl](https://github.com/JuliaPatents/PatentsLandscapes.jl).
To use it, import the PatentsLandscapes package (included in this package's dependencies):

```julia
using PatentsLandscapes
```

## Getting started

The main purpose of this package is to import patent metadata as exported from [Lens.org](https://www.lens.org/) in the jsonlines (`.jsonl`) format.

The package supports two data models: 

* An in-memory object model similar to the original JSON, using Julia structs
* An SQLite-based relational model that offers indexed and fast property-based and full-text search, aggregation, and more

The [PatentsLandscapes.jl](https://github.com/JuliaPatents/PatentsLandscapes.jl) API is currently only implemented for the SQLite model.

### Using the object model (in-memory)

Loading data from a file `test.jsonl` into memory looks like this:

```julia
applications = PatentsLens.read_jsonl("test.jsonl")
```

The `LensApplication` struct implements the interface defined in [PatentsBase.jl](https://github.com/JuliaPatents/PatentsBase.jl).

The dataset can easily be elevated to the simple family level:

```julia
families = PatentsLens.aggregate_families(applications)
```

## Using the SQLite database

To begin using the SQLite model, create a new database:

```julia
db = LensDB("database.db")
```

This will create a new SQLite database at the specified path and initialize it with the PatentsLens schema.

Data can then be loaded into the new database like this:

```julia
PatentsLens.load_jsonl!(db, "test.jsonl")
```

Because the data needs to be transformed into a relational form, this step may take a while.

Data can be retrieved from the database and converted back into the object model:

```julia
all_apps = applications(db)
all_fams = families(db)
```

Subsets of the data can be created and accessed using PatentsBase's Filter API:

```julia
# Retrieve all patent families from the database that mention polylactic acid in their abstract
pla_fams = families(db, ContentFilter("polylactic OR PLA", AbstractSearch))
```
