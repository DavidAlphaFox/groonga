/* -*- c-basic-offset: 2 -*- */
/*
  Copyright(C) 2009-2018 Brazil

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License version 2.1 as published by the Free Software Foundation.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#pragma once

#include "grn.h"

#ifdef GRN_WITH_MESSAGE_PACK
# define _CRT_SECURE_NO_WARNINGS
# include <msgpack.h>
# undef _CRT_SECURE_NO_WARNINGS

# if MSGPACK_VERSION_MAJOR < 1
typedef unsigned int msgpack_size_t;

#  define msgpack_pack_str(packer, size) msgpack_pack_raw(packer, size)
#  define msgpack_pack_str_body(packer, value, size) \
  msgpack_pack_raw_body(packer, value, size)

#  define MSGPACK_OBJECT_STR MSGPACK_OBJECT_RAW
#  define MSGPACK_OBJECT_FLOAT MSGPACK_OBJECT_DOUBLE

#  define MSGPACK_OBJECT_STR_PTR(object)  (object)->via.raw.ptr
#  define MSGPACK_OBJECT_STR_SIZE(object) (object)->via.raw.size

#  define MSGPACK_OBJECT_FLOAT_VALUE(object) (object)->via.dec

#  define MSGPACK_UNPACKER_NEXT(unpacker, unpacked)     \
  msgpack_unpacker_next((unpacker), (unpacked))
# else /* MSGPACK_VERSION_MAJOR < 1 */
typedef size_t msgpack_size_t;

#  define MSGPACK_OBJECT_STR_PTR(object)  (object)->via.str.ptr
#  define MSGPACK_OBJECT_STR_SIZE(object) (object)->via.str.size

#  define MSGPACK_OBJECT_FLOAT_VALUE(object) (object)->via.f64

#  define MSGPACK_UNPACKER_NEXT(unpacker, unpacked)                     \
  msgpack_unpacker_next((unpacker), (unpacked)) == MSGPACK_UNPACK_SUCCESS
# endif /* MSGPACK_VERSION_MAJOR < 1 */

grn_rc grn_msgpack_pack_raw_internal(grn_ctx *ctx,
                                     msgpack_packer *packer,
                                     const char *value,
                                     unsigned int value_size,
                                     grn_id value_domain);
grn_rc grn_msgpack_pack_internal(grn_ctx *ctx,
                                 msgpack_packer *packer,
                                 grn_obj *value);
grn_rc grn_msgpack_unpack_array_internal(grn_ctx *ctx,
                                         msgpack_object_array *array,
                                         grn_obj *vector);
# if MSGPACK_VERSION_MAJOR >= 1
int64_t grn_msgpack_unpack_ext_time_internal(grn_ctx *ctx,
                                             msgpack_object_ext *ext);
# endif /* MSGPACK_VERSION_MAJOR >= 1 */


#endif /* GRN_WITH_MESSAGE_PACK */
