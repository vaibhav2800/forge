// on document ready, show chart
$(showChart);

var chartDivId = 'chartcontainer';
var chart;

function showChart() {
    if (chart) {
        chart.destroy();
        chart = undefined;
    }

    var baseDays = Number($('#basedays')[0].value),
        basePrice = Number($('#baseprice')[0].value),
        extraDayPrice = Number($('#extradayprice')[0].value),
        maxDays = Number($('#maxdays')[0].value);

    if (isNaN(baseDays) || isNaN(basePrice) || isNaN(extraDayPrice) ||
            isNaN(maxDays) ||
            baseDays < 0 || maxDays < baseDays) {
        $('#' + chartDivId).text('Invalid input values');
        return;
    }

    var totalPrice = [{days: baseDays, price: basePrice}];
    for (var d = baseDays + 1, p = basePrice; d <= maxDays; d++) {
        p += extraDayPrice;
        totalPrice.push({days: d, price: p});
    }

    chart = new Highcharts.Chart({
        chart: { renderTo: chartDivId },
          title: { text: 'HSL Season Ticket Price' },
          xAxis: { title: { text: 'days' } },
          yAxis: [{
              title: { text: 'Total price' }
          }, {
              title: { text: 'Price per day' }
          }],
          tooltip: { valueDecimals: 2 },
          series: [{
              name: 'Total price',
          data: totalPrice.map(function(k) { return {x: k.days, y: k.price} })
          }, {
              name: 'Price per day',
          yAxis: 1,
          data: totalPrice.map(function(k) {
              return {x: k.days, y: k.price / k.days};
          })
          }],
    });
}
