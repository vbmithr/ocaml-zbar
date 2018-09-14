/*
 * Copyright (c) 2013 Vincent Bernardoff <vb@luminar.eu.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/custom.h>

#include <zbar.h>

#define Symbol_val(v) (*((zbar_symbol_t **) Data_custom_val(v)))
#define Symbol_set_val(v) (*((zbar_symbol_set_t **) Data_custom_val(v)))
#define Image_val(v) (*((zbar_image_t **) Data_custom_val(v)))
#define Image_scanner_val(v) (*((zbar_image_scanner_t **) Data_custom_val(v)))
#define Video_val(v) (*((zbar_video_t **) Data_custom_val(v)))

static void zbar_symbol_finalize(value symbol) {}
static void zbar_symbol_set_finalize(value symbol) {}
static void zbar_image_finalize(value image) {
    zbar_image_destroy(Image_val(image));
}
static void zbar_image_scanner_finalize(value scan) {
    zbar_image_scanner_destroy(Image_scanner_val(scan));
}
static void zbar_video_finalize(value video) {
    zbar_video_destroy(Video_val(video));
}

#define Gen_custom_block(SNAME, CNAME, MNAME)                           \
    static int compare_##SNAME(value a, value b) {                      \
        CNAME *aa = MNAME(a), *bb = MNAME(b);                           \
        return (aa == bb ? 0 : (aa < bb ? -1 : 1));                     \
    }                                                                   \
                                                                        \
    static struct custom_operations zbar_##SNAME##_ops = {              \
        .identifier = "zbar_" #SNAME,                                   \
        .finalize = zbar_##SNAME##_finalize,                            \
        .compare = compare_##SNAME,                                     \
        .compare_ext = custom_compare_ext_default,                      \
        .hash = custom_hash_default,                                    \
        .serialize = custom_serialize_default,                          \
        .deserialize = custom_deserialize_default                       \
    };                                                                  \
                                                                        \
    static value alloc_##SNAME (CNAME *a) {                             \
        value custom = alloc_custom(&zbar_##SNAME##_ops, sizeof(CNAME *), 0, 1); \
        MNAME(custom) = a;                                              \
        return custom;                                                  \
    }

Gen_custom_block(symbol, zbar_symbol_t, Symbol_val)
Gen_custom_block(symbol_set, zbar_symbol_set_t, Symbol_set_val)
Gen_custom_block(image, zbar_image_t, Image_val)
Gen_custom_block(image_scanner, zbar_image_scanner_t, Image_scanner_val)
Gen_custom_block(video, zbar_video_t, Video_val)

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

CAMLprim value stub_symbol_next(value symbol) {
  CAMLparam1(symbol);
  CAMLlocal2(r, next_symbol);
  const zbar_symbol_t *next;

  next = zbar_symbol_next(Symbol_val(symbol));
  if (next == NULL)
      CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      next_symbol = alloc_symbol((zbar_symbol_t *)next);
      Store_field(r, 0, symbol);
      CAMLreturn(r);
  }
}

CAMLprim value stub_symbol_get_type(value symbol) {
    return Val_int(zbar_symbol_get_type(Symbol_val(symbol)));
}

CAMLprim value stub_symbol_get_data(value symbol) {
  CAMLparam1(symbol);
  CAMLreturn(caml_copy_string(zbar_symbol_get_data(Symbol_val(symbol))));
}

/* zbar_symbol_set_* */

CAMLprim value stub_symbol_set_get_size(value sset) {
    return Val_int(zbar_symbol_set_get_size(Symbol_set_val(sset)));
}

CAMLprim value stub_symbol_set_first_symbol(value sset)
{
  CAMLparam1(sset);
  CAMLlocal2(r, symbol);
  const zbar_symbol_t *next;

  next = zbar_symbol_set_first_symbol(Symbol_set_val(sset));
  if (next == NULL)
    CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      symbol = alloc_symbol((zbar_symbol_t*) next);
      Store_field(r, 0, symbol);
      CAMLreturn(r);
    }
}

/* zbar_image_* */

CAMLprim value stub_image_get_symbols(value image) {
  CAMLparam1(image);
  CAMLlocal2(r, sset);
  const zbar_symbol_set_t *csset;

  csset = zbar_image_get_symbols(Image_val(image));

  if (csset == NULL)
    CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      sset = alloc_symbol_set((zbar_symbol_set_t *)csset);
      Store_field(r, 0, sset);
      CAMLreturn(r);
  }
}

CAMLprim value stub_image_first_symbol(value image)
{
  CAMLparam1(image);
  CAMLlocal2(r, symbol);
  const zbar_symbol_t *csym;

  csym = zbar_image_first_symbol(Image_val(image));
  if (csym == NULL)
      CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      symbol = alloc_symbol((zbar_symbol_t *)csym);
      Store_field(r, 0, symbol);
      CAMLreturn(r);
  }
}

CAMLprim value stub_image_convert(value image, value fmt) {
  CAMLparam2(image, fmt);
  CAMLlocal2(r, converted);
  unsigned long *cfmt = (unsigned long*) String_val(fmt);
  zbar_image_t* cconverted = zbar_image_convert(Image_val(image), *cfmt);
  if (cconverted == NULL)
      CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      converted = alloc_image(cconverted);
      Store_field(r, 0, converted);
      CAMLreturn(r);
  }
}

/* zbar_image_scanner_* */

CAMLprim value stub_image_scanner_create(value unit) {
  CAMLparam1(unit);
  CAMLlocal1(scanner);
  scanner = alloc_image_scanner(zbar_image_scanner_create());
  CAMLreturn(scanner);
}

CAMLprim value stub_image_scanner_set_config(value scanner,
                                             value sym,
                                             value conf, value v) {
    return Val_int(zbar_image_scanner_set_config(Image_scanner_val(scanner),
                                                 Int_val(sym),
                                                 Int_val(conf), Int_val(v)));
}

CAMLprim value stub_scan_image(value scanner, value image) {
    return Val_int(zbar_scan_image(Image_scanner_val(scanner),
                                   Image_val(image)));
}

CAMLprim value stub_image_scanner_get_results(value scanner) {
  CAMLparam1(scanner);
  CAMLlocal2(r, sset);
  const zbar_symbol_set_t *csset;
  csset = zbar_image_scanner_get_results(Image_scanner_val(scanner));
  if (csset == NULL)
      CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      sset = alloc_symbol_set((zbar_symbol_set_t *)csset);
      Store_field(r, 0, sset);
      CAMLreturn(r);
  }
  CAMLreturn(r);
}

CAMLprim value stub_image_scanner_enable_cache(value scanner, value v) {
    zbar_image_scanner_enable_cache(Image_scanner_val(scanner),
                                    Bool_val(v));
    return Val_unit;
}

/* zbar_video_* */

CAMLprim value stub_video_create(value unit) {
  CAMLparam1(unit);
  CAMLlocal1(video);
  zbar_video_t* cvideo;
  cvideo = zbar_video_create();
  video = alloc_video(cvideo);
  CAMLreturn(video);
}

CAMLprim value stub_video_open(value video, value devname) {
    return Val_int(zbar_video_open(Video_val(video),
                                   String_val(devname)));
}

CAMLprim value stub_video_get_fd(value video) {
    CAMLparam1(video);
    CAMLlocal1(r);
    int fd = zbar_video_get_fd(Video_val(video));

    if (fd == -1)
        CAMLreturn(Val_int(0));
    else {
        r = caml_alloc(1, 0);
        Store_field(r, 0, Int_val(fd));
        CAMLreturn(r);
    }
}

CAMLprim value stub_video_request_size(value video, value w, value h) {
    return Val_int(zbar_video_request_size(Video_val(video),
                                           Int_val(w),
                                           Int_val(h)));
}

CAMLprim value stub_video_request_interface(value video, value version) {
    return Val_int(zbar_video_request_interface(Video_val(video),
                                                Int_val(version)));
}

CAMLprim value stub_video_request_iomode(value video, value iomode) {
    return Val_int(zbar_video_request_iomode(Video_val(video),
                                             Int_val(iomode)));
}

CAMLprim value stub_video_get_width(value video) {
    return Val_int(zbar_video_get_width((Video_val(video))));
}

CAMLprim value stub_video_get_height(value video) {
    return Val_int(zbar_video_get_height(Video_val(video)));
}

CAMLprim value stub_video_init(value video, value format) {
    return Val_int(zbar_video_init(Video_val(video),
                                   Long_val(format)));
}

CAMLprim value stub_video_enable(value video, value enable) {
    return Val_int(zbar_video_enable(Video_val(video),
                                     Bool_val(enable)));
}

CAMLprim value stub_video_next_image(value video) {
  CAMLparam1(video);
  CAMLlocal2(r, image);
  zbar_image_t *cimage;

  cimage = zbar_video_next_image(Video_val(video));

  if (cimage == NULL)
    CAMLreturn(Val_int(0));
  else {
      r = caml_alloc(1, 0);
      Store_field(r, 0, alloc_image(cimage));
      CAMLreturn(r);
  }
}

CAMLprim value stub_video_error_string(value video, value verbosity) {
  CAMLparam2(video, verbosity);
  CAMLlocal1(errstr);
  const char *cerrstr;
  cerrstr = zbar_video_error_string(Video_val(video), Int_val(verbosity));
  errstr = caml_copy_string(cerrstr);
  CAMLreturn(errstr);
}
