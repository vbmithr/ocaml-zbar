#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>

#include <zbar.h>

/* zbar_* */

CAMLprim value stub_set_verbosity(value verbosity)
{
  zbar_set_verbosity(Int_val(verbosity));
  return Val_unit;
}

CAMLprim value stub_increase_verbosity(value unit)
{
  zbar_increase_verbosity();
  return Val_unit;
}

/* zbar_symbol_* */

CAMLprim value stub_symbol_next(value zbar_symbol_p)
{
  CAMLparam1(zbar_symbol_p);
  CAMLlocal1(r);
  const zbar_symbol_t *next;

  if ((next = zbar_symbol_next((const zbar_symbol_t*)zbar_symbol_p)) == NULL)
    CAMLreturn(Val_int(0));
  else
    {
      r = caml_alloc(1, 0);
      Store_field(r, 0, (value)next);
      CAMLreturn(r);
    }
}

CAMLprim value stub_symbol_get_type(value zbar_symbol_p)
{
  CAMLparam1(zbar_symbol_p);
  CAMLreturn(Val_int(zbar_symbol_get_type((const zbar_symbol_t*)zbar_symbol_p)));
}

CAMLprim value stub_symbol_get_data(value zbar_symbol_p)
{
  CAMLparam1(zbar_symbol_p);
  CAMLreturn(caml_copy_string(zbar_symbol_get_data((const zbar_symbol_t*)zbar_symbol_p)));
}

/* zbar_symbol_set_* */

CAMLprim value stub_symbol_set_get_size(value zbar_symbol_set_p)
{
  CAMLparam1(zbar_symbol_set_p);
  CAMLreturn(Val_int(zbar_symbol_set_get_size((const zbar_symbol_set_t*)zbar_symbol_set_p)));
}

CAMLprim value stub_symbol_set_first_symbol(value zbar_symbol_set_p)
{
  CAMLparam1(zbar_symbol_set_p);
  CAMLlocal1(r);
  const zbar_symbol_t *next;

  if ((next = zbar_symbol_set_first_symbol((const zbar_symbol_set_t*)zbar_symbol_set_p)) == NULL)
    CAMLreturn(Val_int(0));
  else
    {
      r = caml_alloc(1, 0);
      Store_field(r, 0, (value)next);
      CAMLreturn(r);
    }
}

/* zbar_image_* */

CAMLprim value stub_image_destroy(value zbar_image_p)
{
  CAMLparam1(zbar_image_p);
  zbar_image_destroy((zbar_image_t *)zbar_image_p);
  CAMLreturn(Val_unit);
}

CAMLprim value stub_image_get_symbols(value zbar_image_p)
{
  CAMLparam1(zbar_image_p);
  CAMLlocal1(r);
  const zbar_symbol_set_t *next;

  if ((next = zbar_image_get_symbols((const zbar_image_t*)zbar_image_p)) == NULL)
    CAMLreturn(Val_int(0));
  else
    {
      r = caml_alloc(1, 0);
      Store_field(r, 0, (value)next);
      CAMLreturn(r);
    }
}

CAMLprim value stub_image_first_symbol(value zbar_image_p)
{
  CAMLparam1(zbar_image_p);
  CAMLlocal1(r);
  const zbar_symbol_t *next;

  if ((next = zbar_image_first_symbol((const zbar_image_t*)zbar_image_p)) == NULL)
    CAMLreturn(Val_int(0));
  else
    {
      r = caml_alloc(1, 0);
      Store_field(r, 0, (value)next);
      CAMLreturn(r);
    }
}

CAMLprim value stub_image_convert(value zbar_image_p, value fmt)
{
  CAMLparam2(zbar_image_p, fmt);
  CAMLreturn((value)zbar_image_convert((const zbar_image_t *)zbar_image_p, (unsigned long)Int32_val(fmt)));
}

/* zbar_image_scanner_* */

CAMLprim value stub_image_scanner_create(value unit)
{
  CAMLparam1(unit);
  CAMLreturn((value)zbar_image_scanner_create());
}

CAMLprim value stub_image_scanner_destroy(value zbar_image_scanner_p)
{
  CAMLparam1(zbar_image_scanner_p);
  zbar_image_scanner_destroy((zbar_image_scanner_t *)zbar_image_scanner_p);
  CAMLreturn(Val_unit);
}

CAMLprim value stub_image_scanner_set_config(value zbar_image_scanner_p, value sym, value conf, value v)
{
  CAMLparam4(zbar_image_scanner_p, sym, conf, v);
  CAMLreturn(Val_int(zbar_image_scanner_set_config((zbar_image_scanner_t *)zbar_image_scanner_p,
                                                   Int_val(sym), Int_val(conf), Int_val(v))));
}

CAMLprim value stub_scan_image(value zbar_image_scanner_p, value image)
{
  CAMLparam2(zbar_image_scanner_p, image);
  CAMLreturn(Val_int(zbar_scan_image((zbar_image_scanner_t *)zbar_image_scanner_p,
                                     (zbar_image_t *)image
                                     )));
}

CAMLprim value stub_image_scanner_get_results(value zbar_image_scanner_p)
{
  CAMLparam1(zbar_image_scanner_p);
  CAMLreturn((value)zbar_image_scanner_get_results((zbar_image_scanner_t *)zbar_image_scanner_p));
}

CAMLprim value stub_image_scanner_enable_cache(value zbar_image_scanner_p, value v)
{
  CAMLparam2(zbar_image_scanner_p, v);
  zbar_image_scanner_enable_cache((zbar_image_scanner_t *)zbar_image_scanner_p, Int_val(v));
  CAMLreturn(Val_unit);
}

/* zbar_video_* */

CAMLprim value stub_video_create(value unit)
{
  CAMLparam1(unit);
  CAMLreturn((value)zbar_video_create());
}

CAMLprim value stub_video_destroy(value video)
{
  CAMLparam1(video);
  zbar_video_destroy((zbar_video_t *)video);
  CAMLreturn(Val_unit);
}

CAMLprim value stub_video_open(value video, value devname)
{
  CAMLparam2(video, devname);
  CAMLreturn(Val_int(zbar_video_open((zbar_video_t *)video, String_val(devname))));
}

CAMLprim value stub_video_get_fd(value video)
{
  CAMLparam1(video);
  CAMLreturn(Val_int(zbar_video_get_fd((zbar_video_t *)video)));
}

CAMLprim value stub_video_request_size(value video, value a, value b)
{
  CAMLparam3(video, a, b);
  CAMLreturn(Val_int(zbar_video_request_size((zbar_video_t *)video,
                                             (unsigned int)Int_val(a),
                                             (unsigned int)Int_val(b)
                                             )));
}

CAMLprim value stub_video_request_interface(value video, value a)
{
  CAMLparam2(video, a);
  CAMLreturn(Val_int(zbar_video_request_interface((zbar_video_t *)video,
                                                  Int_val(a)
                                                  )));
}

CAMLprim value stub_video_request_iomode(value video, value a)
{
  CAMLparam2(video, a);
  CAMLreturn(Val_int(zbar_video_request_iomode((zbar_video_t *)video,
                                               Int_val(a)
                                               )));
}

CAMLprim value stub_video_get_width(value video)
{
  CAMLparam1(video);
  CAMLreturn(Val_int(zbar_video_get_width((zbar_video_t *)video)));
}

CAMLprim value stub_video_get_height(value video)
{
  CAMLparam1(video);
  CAMLreturn(Val_int(zbar_video_get_height((zbar_video_t *)video)));
}

CAMLprim value stub_video_init(value video, value a)
{
  CAMLparam2(video, a);
  CAMLreturn(Val_int(zbar_video_init((zbar_video_t *)video,
                                     (unsigned long)Int_val(a)
                                     )));
}

CAMLprim value stub_video_enable(value video, value a)
{
  CAMLparam2(video, a);
  CAMLreturn(Val_int(zbar_video_enable((zbar_video_t *)video,
                                       Int_val(a)
                                       )));
}

CAMLprim value stub_video_next_image(value video)
{
  CAMLparam1(video);
  CAMLlocal1(r);
  zbar_image_t *next;

  if ((next = (zbar_image_t *)zbar_video_next_image((zbar_video_t *)video)) == NULL)
    CAMLreturn(Val_int(0));
  else
    {
      r = caml_alloc(1, 0);
      Store_field(r, 0, (value)next);
      CAMLreturn(r);
    }
}

CAMLprim value _stub_error_string(value video, value a)
{
  CAMLparam2(video, a);
  CAMLreturn(caml_copy_string(_zbar_error_string((zbar_video_t *)video, Int_val(a))));
}
