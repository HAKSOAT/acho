#[cfg(target_arch = "aarch64")]
use std::{
    arch::aarch64::{uint16x8_t, vceqq_u16, vld1q_dup_u16, vld1q_u16, vst1q_u16},
    mem::{self},
};

use crate::index::Shard;
use crate::{
    add_result::add_result_multiterm_multifield,
    index::{NonUniquePostingListObjectQuery, PostingListObjectQuery},
    search::{FilterSparse, ResultType, SearchResult},
    utils::read_u16,
};
use ahash::AHashSet;



#[cfg(target_arch = "aarch64")]
pub(crate) fn intersection_vector16(
    a: &[u8],
    s_a: usize,
    b: &[u8],
    s_b: usize,
    result_count: &mut i32,
    block_id: usize,
    index: &Shard,
    search_result: &mut SearchResult,
    top_k: usize,
    result_type: &ResultType,
    field_filter_set: &AHashSet<u16>,
    facet_filter: &[FilterSparse],
    non_unique_query_list: &mut [NonUniquePostingListObjectQuery],
    query_list: &mut [PostingListObjectQuery],
    not_query_list: &mut [PostingListObjectQuery],
    phrase_query: bool,
    all_terms_frequent: bool,
) {
    unsafe {
        let mut i_a = 0;
        let mut i_b = 0;
        let vectorlength = mem::size_of::<uint16x8_t>() / mem::size_of::<u16>();
        let st_b = (s_b / vectorlength) * vectorlength;
        while i_a < s_a && i_b < st_b {
            if read_u16(&a[..], i_a * 2) < read_u16(&b[..], i_b * 2) {
                i_a += 1;
                continue;
            } else if read_u16(&a[..], i_a * 2) > read_u16(&b[..], (i_b + vectorlength - 1) * 2) {
                i_b += vectorlength;
                continue;
            }

            let v_a = vld1q_dup_u16(a[(i_a * 2)..].as_ptr() as *const _);
            let v_b = vld1q_u16(b[(i_b * 2)..].as_ptr() as *const _);
            let res_v = vceqq_u16(v_a, v_b);
            let mut res = [0u16; 8];
            vst1q_u16(res.as_mut_ptr(), res_v);
            for i in 0..res.len() {
                if res[i] == 0 {
                    continue;
                }
                query_list[0].p_docid = i_a;
                query_list[1].p_docid = i_b + i;
                add_result_multiterm_multifield(
                    index,
                    (block_id << 16) | read_u16(&a[..], i_a * 2) as usize,
                    result_count,
                    search_result,
                    top_k,
                    result_type,
                    field_filter_set,
                    facet_filter,
                    non_unique_query_list,
                    query_list,
                    not_query_list,
                    phrase_query,
                    f32::MAX,
                    all_terms_frequent,
                );
                break;
            }
            i_a += 1;
        }
        while i_a < s_a && i_b < s_b {
            let a = read_u16(&a[..], i_a * 2);
            let b = read_u16(&b[..], i_b * 2);
            match a.cmp(&b) {
                std::cmp::Ordering::Less => {
                    i_a += 1;
                }
                std::cmp::Ordering::Greater => {
                    i_b += 1;
                }
                std::cmp::Ordering::Equal => {
                    query_list[0].p_docid = i_a;
                    query_list[1].p_docid = i_b;
                    add_result_multiterm_multifield(
                        index,
                        (block_id << 16) | a as usize,
                        result_count,
                        search_result,
                        top_k,
                        result_type,
                        field_filter_set,
                        facet_filter,
                        non_unique_query_list,
                        query_list,
                        not_query_list,
                        phrase_query,
                        f32::MAX,
                        all_terms_frequent,
                    );

                    i_a += 1;
                    i_b += 1;
                }
            }
        }
    }
}

#[cfg(not(any(target_arch = "x86_64", target_arch = "aarch64")))]
pub(crate) fn intersection_vector16(
    a: &[u8],
    s_a: usize,
    b: &[u8],
    s_b: usize,
    result_count: &mut i32,
    block_id: usize,
    index: &Shard,
    search_result: &mut SearchResult,
    top_k: usize,
    result_type: &ResultType,
    field_filter_set: &AHashSet<u16>,
    facet_filter: &[FilterSparse],
    non_unique_query_list: &mut [NonUniquePostingListObjectQuery],
    query_list: &mut [PostingListObjectQuery],
    not_query_list: &mut [PostingListObjectQuery],
    phrase_query: bool,
    all_terms_frequent: bool,
) {
    let mut i_a = 0;
    let mut i_b = 0;
    while i_a < s_a && i_b < s_b {
        let a = read_u16(&a[..], i_a * 2);
        let b = read_u16(&b[..], i_b * 2);
        match a.cmp(&b) {
            std::cmp::Ordering::Less => {
                i_a += 1;
            }
            std::cmp::Ordering::Greater => {
                i_b += 1;
            }
            std::cmp::Ordering::Equal => {
                query_list[0].p_docid = i_a;
                query_list[1].p_docid = i_b;
                add_result_multiterm_multifield(
                    index,
                    (block_id << 16) | a as usize,
                    result_count,
                    search_result,
                    top_k,
                    result_type,
                    field_filter_set,
                    facet_filter,
                    non_unique_query_list,
                    query_list,
                    not_query_list,
                    phrase_query,
                    f32::MAX,
                    all_terms_frequent,
                );

                i_a += 1;
                i_b += 1;
            }
        }
    }
}
