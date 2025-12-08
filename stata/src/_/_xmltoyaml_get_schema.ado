*******************************************************************************
* _xmltoyaml_get_schema
*! v 1.1.0   06Dec2025               by Joao Pedro Azevedo (UNICEF)
* Schema Registry - Returns XML structure definition for each type
* Now includes open_tag and close_tag for element detection
*******************************************************************************

program define _xmltoyaml_get_schema, rclass
    version 14.0
    
    syntax, TYPE(string)
    
    * Initialize defaults
    local xml_root ""
    local xml_filter ""
    local open_tag ""
    local close_tag ""
    local id_attr "id"
    local name_element "com:Name"
    local desc_element "com:Description"
    local extra_attrs ""
    local yaml_fields "id name"
    local list_name "items"
    
    *---------------------------------------------------------------------------
    * Schema definitions for each type
    *---------------------------------------------------------------------------
    
    if ("`type'" == "dataflows") {
        * SDMX Dataflow structure
        local xml_root "str:Dataflow"
        local open_tag "<str:Dataflow "
        local close_tag "</str:Dataflow>"
        local xml_filter "*<str:Dataflow *id=*"
        local id_attr "id"
        local name_element "com:Name"
        local desc_element ""
        local extra_attrs "version agencyID"
        local yaml_fields "id name version agency_id"
        local list_name "dataflows"
    }
    
    else if ("`type'" == "codelists") {
        * Generic codelist items
        local xml_root "str:Code"
        local open_tag "<str:Code "
        local close_tag "</str:Code>"
        local xml_filter "*<str:Code *id=*"
        local id_attr "id"
        local name_element "com:Name"
        local desc_element "com:Description"
        local extra_attrs ""
        local yaml_fields "id name description"
        local list_name "codes"
    }
    
    else if ("`type'" == "countries") {
        * Country codes (CL_COUNTRY)
        local xml_root "str:Code"
        local open_tag "<str:Code "
        local close_tag "</str:Code>"
        local xml_filter "*<str:Code *id=*"
        local id_attr "id"
        local name_element "com:Name"
        local desc_element ""
        local extra_attrs ""
        local yaml_fields "id name"
        local list_name "countries"
    }
    
    else if ("`type'" == "regions") {
        * Regional codes (CL_WORLD_REGIONS)
        local xml_root "str:Code"
        local open_tag "<str:Code "
        local close_tag "</str:Code>"
        local xml_filter "*<str:Code *id=*"
        local id_attr "id"
        local name_element "com:Name"
        local desc_element ""
        local extra_attrs ""
        local yaml_fields "id name"
        local list_name "regions"
    }
    
    else if ("`type'" == "dimensions") {
        * DSD Dimension definitions
        local xml_root "str:Dimension"
        local open_tag "<str:Dimension "
        local close_tag "</str:Dimension>"
        local xml_filter "*<str:Dimension *id=*"
        local id_attr "id"
        local name_element ""
        local desc_element ""
        local extra_attrs "position"
        local yaml_fields "id position codelist"
        local list_name "dimensions"
    }
    
    else if ("`type'" == "attributes") {
        * DSD Attribute definitions
        local xml_root "str:Attribute"
        local open_tag "<str:Attribute "
        local close_tag "</str:Attribute>"
        local xml_filter "*<str:Attribute *id=*"
        local id_attr "id"
        local name_element ""
        local desc_element ""
        local extra_attrs ""
        local yaml_fields "id codelist"
        local list_name "attributes"
    }
    
    else if ("`type'" == "indicators") {
        * Indicator codelist (CL_UNICEF_INDICATOR)
        local xml_root "str:Code"
        local open_tag "<str:Code "
        local close_tag "</str:Code>"
        local xml_filter "*<str:Code *id=*"
        local id_attr "id"
        local name_element "com:Name"
        local desc_element "com:Description"
        local extra_attrs ""
        local yaml_fields "code name description category"
        local list_name "indicators"
    }
    
    * Return schema
    return local xml_root "`xml_root'"
    return local open_tag "`open_tag'"
    return local close_tag "`close_tag'"
    return local xml_filter "`xml_filter'"
    return local id_attr "`id_attr'"
    return local name_element "`name_element'"
    return local desc_element "`desc_element'"
    return local extra_attrs "`extra_attrs'"
    return local yaml_fields "`yaml_fields'"
    return local list_name "`list_name'"
end
