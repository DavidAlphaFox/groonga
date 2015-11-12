/* -*- c-basic-offset: 2 -*- */
/*
  Copyright(C) 2015 Brazil

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

#ifndef GRN_TS_EXPR_NODE_H
#define GRN_TS_EXPR_NODE_H

#include "ts_buf.h"
#include "ts_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  GRN_TS_EXPR_ID_NODE,     /* ID (_id). */
  GRN_TS_EXPR_SCORE_NODE,  /* Score (_score). */
  GRN_TS_EXPR_KEY_NODE,    /* Key (_key). */
  GRN_TS_EXPR_VALUE_NODE,  /* Embedded value (_value). */
  GRN_TS_EXPR_CONST_NODE,  /* Const. */
  GRN_TS_EXPR_COLUMN_NODE, /* Column. */
  GRN_TS_EXPR_OP_NODE,     /* Operator. */
  GRN_TS_EXPR_BRIDGE_NODE  /* Bridge to a subexpression. */
} grn_ts_expr_node_type;

#define GRN_TS_EXPR_NODE_COMMON_MEMBERS\
  grn_ts_expr_node_type type; /* Node type. */\
  grn_ts_data_kind data_kind; /* Abstract data type. */\
  grn_ts_data_type data_type; /* Detailed data type. */

typedef struct {
  GRN_TS_EXPR_NODE_COMMON_MEMBERS
} grn_ts_expr_node;

/* grn_ts_expr_id_node_open() creates a node associated with IDs (_id). */
grn_rc grn_ts_expr_id_node_open(grn_ctx *ctx, grn_ts_expr_node **node);

/*
 * grn_ts_expr_score_node_open() creates a node associated with scores
 * (_score).
 */
grn_rc grn_ts_expr_score_node_open(grn_ctx *ctx, grn_ts_expr_node **node);

/* grn_ts_expr_key_node_open() creates a node associated with keys (_key). */
grn_rc grn_ts_expr_key_node_open(grn_ctx *ctx, grn_obj *table,
                                 grn_ts_expr_node **node);

/*
 * grn_ts_expr_value_node_open() creates a node associated with values
 * (_value).
 */
grn_rc grn_ts_expr_value_node_open(grn_ctx *ctx, grn_obj *table,
                                   grn_ts_expr_node **node);

/* grn_ts_expr_const_node_open() creates a node associated with a const. */
grn_rc grn_ts_expr_const_node_open(grn_ctx *ctx, grn_ts_data_kind kind,
                                   const void *value, grn_ts_expr_node **node);

/* grn_ts_expr_column_node_open() creates a node associated with a column. */
grn_rc grn_ts_expr_column_node_open(grn_ctx *ctx, grn_obj *column,
                                    grn_ts_expr_node **node);

/* grn_ts_expr_op_node_open() creates a node associated with an operator. */
grn_rc grn_ts_expr_op_node_open(grn_ctx *ctx, grn_ts_op_type op_type,
                                grn_ts_expr_node **args, size_t n_args,
                                grn_ts_expr_node **node);

/* grn_ts_expr_bridge_node_open() creates a node associated with a bridge. */
grn_rc grn_ts_expr_bridge_node_open(grn_ctx *ctx, grn_ts_expr_node *src,
                                    grn_ts_expr_node *dest,
                                    grn_ts_expr_node **node);

/* grn_ts_expr_node_close() destroys a node. */
void grn_ts_expr_node_close(grn_ctx *ctx, grn_ts_expr_node *node);

/* grn_ts_expr_node_evaluate() evaluates a subtree. */
grn_rc grn_ts_expr_node_evaluate(grn_ctx *ctx, grn_ts_expr_node *node,
                                 const grn_ts_record *in, size_t n_in,
                                 void *out);

/* grn_ts_expr_node_evaluate_to_buf() evaluates a subtree. */
grn_rc grn_ts_expr_node_evaluate_to_buf(grn_ctx *ctx, grn_ts_expr_node *node,
                                        const grn_ts_record *in, size_t n_in,
                                        grn_ts_buf *out);

/* grn_ts_expr_node_filter() filters records. */
grn_rc grn_ts_expr_node_filter(grn_ctx *ctx, grn_ts_expr_node *node,
                               grn_ts_record *in, size_t n_in,
                               grn_ts_record *out, size_t *n_out);

/* grn_ts_expr_node_adjust() updates scores. */
grn_rc grn_ts_expr_node_adjust(grn_ctx *ctx, grn_ts_expr_node *node,
                               grn_ts_record *io, size_t n_io);

#ifdef __cplusplus
}
#endif

#endif /* GRN_TS_EXPR_NODE_H */
