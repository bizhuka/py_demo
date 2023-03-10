class ZCL_ZC_PY000_ORGASSIGNMENT definition
  public
  inheriting from CL_SADL_GTK_EXPOSURE_MPC
  final
  create public .

public section.
protected section.

  methods GET_PATHS
    redefinition .
  methods GET_TIMESTAMP
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZC_PY000_ORGASSIGNMENT IMPLEMENTATION.


  method GET_PATHS.
et_paths = VALUE #(
( `CDS~ZC_PY000_ORGASSIGNMENT` )
).
  endmethod.


  method GET_TIMESTAMP.
RV_TIMESTAMP = 20230309043647.
  endmethod.
ENDCLASS.
