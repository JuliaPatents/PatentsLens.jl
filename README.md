# PatentsLens.jl

[![codecov.io](http://codecov.io/github/jfb-h/PatentsLens.jl/coverage.svg?branch=master)](http://codecov.io/github/jfb-h/PatentsLens.jl?branch=master)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://jfb-h.github.io/PatentsLens.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://jfb-h.github.io/PatentsLens.jl/dev)


*A helper package for reading Lens.org patent data for use in Patents.jl.*

## Installation

The package is currently not registered but can be added directly via the github package URL.
From the julia REPL, type `]` to enter the Pkg REPL and run:

```julia 
pkg> add https://github.com/jfb-h/PatentsLens.jl

julia> using PatentsLens
``` 

## Example

This package does exactly one thing: Import patent metadata as exported from [Lens.org](https://www.lens.org/) in the jsonlines (`.jsonl`) format to a vector of `Patents.Application`'s. 

Loading data in a file `test.jsonl` looks like this:

```julia
julia> PatentsLens.read("test.jsonl")
500-element Vector{Patents.Application}:
 000-008-730-872-158 | 2005-09-14 | CN1668902A
 000-039-658-336-810 | 1996-10-02 | EP0734313A1
 000-041-908-077-974 | 2011-04-13 | GB201103495D0
 000-044-326-144-587 | 2018-12-14 | CN108995084A
 000-053-788-642-999 | 1984-06-15 | AT7863T
 000-085-962-043-833 | 2004-02-26 | DE10236830A1
 000-158-289-997-294 | 2016-01-20 | EP2973744A1
 000-174-954-386-873 | 2016-05-11 | CN105563695A
 [...]
```

