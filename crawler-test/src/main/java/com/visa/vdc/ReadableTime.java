package com.visa.vdc;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;

public class ReadableTime {

    private ReadableTime() {

    }

    public static final List<Long> TIMES = Arrays.asList(
            TimeUnit.DAYS.toMillis(365),
            TimeUnit.DAYS.toMillis(30),
            TimeUnit.DAYS.toMillis(1),
            TimeUnit.HOURS.toMillis(1),
            TimeUnit.MINUTES.toMillis(1),
            TimeUnit.SECONDS.toMillis(1));
    public static final List<String> TIMES_STRING = Arrays.asList("year", "month", "day", "hour", "minute", "second");

    public static String format(long durationInMillis) {

        StringBuffer res = new StringBuffer();
        for (int i = 0; i < ReadableTime.TIMES.size(); i++) {
            Long current = ReadableTime.TIMES.get(i);
            long temp = (long) Math.ceil(durationInMillis / current);
            if (temp > 0) {
                res.append(temp).append(" ").append(ReadableTime.TIMES_STRING.get(i)).append(temp != 1 ? "s" : "").append(" ");
            }
            durationInMillis = durationInMillis % current;
        }
        if ("".equals(res.toString())) {
            return "0 seconds ago";
        } else {
            return res.toString();
        }
    }
}
