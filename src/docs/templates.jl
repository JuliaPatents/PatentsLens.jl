using DocStringExtensions

@template TYPES =
    """
    $(TYPEDEF)
    $(DOCSTRING)
    # Fields:
    $(TYPEDFIELDS)
    """

@template METHODS =
    """
    $(TYPEDSIGNATURES)
    $(DOCSTRING)
    """
