// Multi-timer Library
// Author: Testicular Slingshot
// MIT License

// The interval of the main timer event, lower values provide more accurate timing.
float MT_MAIN_INTERVAL = 0.05;

// How many data fields there are for a single timer.
integer MT_NUM_OF_DATA_FIELDS = 4;

// Names are separated from the data so that finding a timer with llListFindList
// won't conflict with data of the same type.
list mtTimerNames;

// Timer data is strided in relation to mtTimerNames: [active, interval, count_remaining, last_run_time]
list mtTimerData;

// Timers marked for cleanup at the end of the main timer event.
list mtDeadTimers;

// Creates a timer. Setting count to less than 0 means infinite.
mt_create_timer(string name, float interval, integer count)
{
    mtTimerNames += [name];
    mtTimerData += [FALSE, interval, count, 0.0];

    // Activate main timer.
    if (llGetListLength(mtTimerNames) == 1)
        llSetTimerEvent(MT_MAIN_INTERVAL);
}

// Removes a timer.
mt_remove_timer(string name)
{
    integer t_idx = llListFindList(mtTimerNames, [name]);
    if (t_idx == -1) return;
    mtTimerNames = llDeleteSubList(mtTimerNames, t_idx, t_idx);
    integer data_idx = t_idx * MT_NUM_OF_DATA_FIELDS;
    mtTimerData = llDeleteSubList(mtTimerData, data_idx, data_idx + MT_NUM_OF_DATA_FIELDS - 1);

    // Deactivate main timer.
    if (llGetListLength(mtTimerNames) <= 0)
        llSetTimerEvent(0.0);
}

// Starts a timer.
mt_start_timer(string name)
{
    integer t_idx = llListFindList(mtTimerNames, [name]);
    mt_update_timer_data(t_idx, [TRUE], 0);
    mt_update_timer_data(t_idx, [llGetTime()], 3);
}

// Stops a timer.
mt_stop_timer(string name)
{
    integer t_idx = llListFindList(mtTimerNames, [name]);
    mt_update_timer_data(t_idx, [FALSE], 0);
}

// Replaces a singular item in the timer data list, field_idx is not item index.
integer mt_update_timer_data(integer t_idx, list data, integer field_idx)
{
    if (t_idx < 0 || llGetListLength(data) != 1 || field_idx < 0 || field_idx > MT_NUM_OF_DATA_FIELDS - 1)
        return FALSE;
    integer datum_idx = (t_idx * MT_NUM_OF_DATA_FIELDS) + field_idx;
    mtTimerData = llListReplaceList(mtTimerData, data, datum_idx, datum_idx);
    return TRUE;
}

// Checks if this timer should run and if so then updates data.
mt_check_timer(integer t_idx)
{
    string name = llList2String(mtTimerNames, t_idx);
    integer data_idx = t_idx * MT_NUM_OF_DATA_FIELDS;
    integer active = llList2Integer(mtTimerData, data_idx);
    float interval = llList2Float(mtTimerData, data_idx+1);
    integer count_remaining = llList2Integer(mtTimerData, data_idx+2);
    float last_run_time = llList2Float(mtTimerData, data_idx+3);
    float elapsed_time = llGetTime() - last_run_time;
    if (active && count_remaining != 0 && elapsed_time >= interval)
    {
        mt_handle_timer(name, elapsed_time);
        if (count_remaining > 0)
            mt_update_timer_data(t_idx, [count_remaining - 1], 2);  // Update count remaining.
        mt_update_timer_data(t_idx, [llGetTime()], 3);  // Update last run.
    }
    // Mark timer for cleanup.
    else if (count_remaining == 0)
    {
       mtDeadTimers += [name];
    }
}

// Handle your timers here.
mt_handle_timer(string name, float elapsed_time)
{
    llOwnerSay(name + " " + (string)elapsed_time);
}

default
{
    state_entry()
    {
        // Example code.
        mt_create_timer("t1", 0.2, 2);  // Executes twice at interval of 0.2 seconds.
        mt_start_timer("t1");
        mt_create_timer("t2", 1.0, -1);  // Executes infinite number of times every second.
        mt_start_timer("t2");
        mt_create_timer("t3", 5.0, -1);  // Executes infinite number of times every 5.0 seconds.
        mt_start_timer("t3");
    }

    timer()
    {
        integer num_of_timers = llGetListLength(mtTimerNames);
        integer t_idx;
        for (; t_idx < num_of_timers; ++t_idx)
        {
            mt_check_timer(t_idx);
        }

        // Cleanup
        num_of_timers = llGetListLength(mtDeadTimers);
        if (num_of_timers > 0)
        {
            for (t_idx = 0; t_idx < num_of_timers; ++t_idx)
                mt_remove_timer(llList2String(mtDeadTimers, t_idx));
            mtDeadTimers = [];
        }
    }
}
