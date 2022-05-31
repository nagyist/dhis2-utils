/**
    This function is used for cleaning up gaps of sort_order column in table optionvalue.
    An example of corrupted sort_orders can be [2,5,7].
    After cleaning up, the correct sort_order list should be [1,2,3].

    Usage: 
        1) Execute below query to create function clean_up_option_sort_order()
        2) Call function by execute "select clean_up_option_sort_order()"
**/
CREATE OR REPLACE FUNCTION clean_up_option_sort_order()
RETURNS text
AS
$$
DECLARE rowCount int;
BEGIN
    UPDATE optionvalue 
    SET sort_order = temp.orderIndex
    FROM 
    ( SELECT optionvalueid, optionsetid, row_number() 
        OVER ( PARTITION BY optionsetid ORDER BY sort_order ) AS orderIndex
        FROM optionvalue ) temp
    WHERE temp.optionvalueid = optionvalue.optionvalueid AND temp.optionsetid = optionvalue.optionsetid AND optionvalue.sort_order <> temp.orderIndex;

    GET DIAGNOSTICS rowCount = ROW_COUNT;
    RETURN 'Updated ' || rowCount || ' records';
END;
$$ LANGUAGE plpgsql;