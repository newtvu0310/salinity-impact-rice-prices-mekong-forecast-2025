import excel "C:\Users\DatTruong\DỮ LIỆU CHẠY DỰ BÁO.xlsx", sheet("Sheet1") firstrow case(lower)
gen weeknum = real(substr(week_month, 2, 1))             
gen monthstr = substr(week_month, 4, 3)                   
gen year = real(substr(week_month, 8, 2)) + 2000
gen month = .
replace month = 1 if monthstr == "jan"
replace month = 2 if monthstr == "feb"
replace month = 3 if monthstr == "mar"
replace month = 4 if monthstr == "apr"
replace month = 5 if monthstr == "may"
replace month = 6 if monthstr == "jun"
replace month = 7 if monthstr == "jul"
replace month = 8 if monthstr == "aug"
replace month = 9 if monthstr == "sep"
replace month =10 if monthstr == "oct"
replace month =11 if monthstr == "nov"
replace month =12 if monthstr == "dec"
gen day = 1 + (weeknum - 1)*7
gen date = mdy(month, day, year)
format date %td
gen week_ts = wofd(date)
format week_ts %tw
tsset week_ts

summarize, detail

//Xử lý mùa vụ
gen week_num = _n // số thứ tự tuần
gen sin52 = sin(2*_pi*week_num/52)
gen cos52 = cos(2*_pi*week_num/52)

*tạo biến để train
gen price = giágạohạtdài
replace price = . in 140
replace price = . in 139
replace price = . in 138
replace price = . in 137
replace price = . in 136
replace price = . in 135
replace price = . in 134
replace price = . in 133
replace price = . in 132
replace price = . in 131
replace price = . in 130
replace price = . in 129

// kiểm tra tính dừng và chạy sai phân
dfuller tb
dfuller giágạohạtdài
dfuller d.giágạohạtdài
gen d_giágạohạtdài = d.giágạohạtdài
dfuller lượngmưa
dfuller diệntíchgieotrồngha
dfuller năngsuấtlúatạha
dfuller sảnlượnglúatấnha

dfuller price
dfuller d.price

drop  h i j k
drop if missing(week_ts)

//kiểm tra tìm q và p
tsline d_giágạohạtdài //kiểm tra bằng mắt
ac  d_giágạohạtdài, name(ACF,replace) lag(20) // kiểm tra tự tương quan
pac d_giágạohạtdài, name(PACF,replace) lag(20) // Tự tương quan liên phần
wntestq d_giágạohạtdài
graph combine ACF PACF, name(Graph, replace)
corrgram d_giágạohạtdài, lag(10)


*Chạy mô hình SARIMAX

//
arima price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arima(0,1,2)
estimates store m1
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]
//

//
arima price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52 , arima(1,1,2) 
estimates store m2
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]
//

//
arima price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arima(2,1,2)
estimates store m3
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]
// ktra mô hình
esttab m*, nogap br mtitles( "ARIMA(0,1,2)" "ARIMA(1,1,2)" "ARIMA(2,1,2)") scalar(LogLikelihood AIC BIC) sfmt(4) star(* 0.1 ** 0.05 *** 0.01)
//


*kiểm định arch là quan trọng và cần thêm vào mô hình
arima price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arima(1,1,2)
//ktra arch test
predict res, residuals
gen res2 = res^2
reg res2 L.res2
estat archlm
//kiểm tra phần dư và phần dư bình phương
tsline res, title("Residuals from ARIMA model")
tsline res2, title("Squared residuals (Volatility)") 
//kiểm định tự tương quan bình phương của phần dư
ac res2, name(ACF2,replace) lag(20) 
pac res2, name(PACF2,replace) lag(20) 
graph combine ACF2 PACF2, name(Graph2, replace)
corrgram res2, lag(10)



*Chạy mô hình SARIMAX - ARCH

arch price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arch(1/1) arima(0,1,2)
estimates store l1
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]

//
arch price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52 , arch(1/1) arima(1,1,2) 
estimates store l2
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]
//
arch price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arch(1/1) arima(2,1,2)
estimates store l3
estat ic
estadd scalar AIC = r(S)[1,5]
estadd scalar BIC = r(S)[1,6]
estadd scalar LogLikelihood = r(S)[1,3]
// ktra mô hình
esttab l*, nogap br mtitles(  "SAX-AR(0,1,2)" "SAX-AR(1,1,2)" "SAX-AR(2,1,2)") scalar(LogLikelihood AIC BIC) sfmt(4) star(* 0.1 ** 0.05 *** 0.01)

//ktra lại mô hình 
arch price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arch(1/1) arima(2,1,2)
//kiểm tra phần dư và phần dư bình phương
predict res12, residuals
gen res123 = res^2
reg res123 L.res123
tsline res12, title("Residuals from ARIMA model")
tsline res123, title("Squared residuals (Volatility)") 
// kiểm định arch test
estat archlm
//kiểm định tự ttương quan bình phương của phần dư
ac res12, name(ACF3,replace) lag(20) 
pac res123, name(PACF3,replace) lag(20) 
graph combine ACF3 PACF3, name(Graph3, replace)
corrgram res123, lag(10)
// kiểm tra phân phối phần dư
histogram res12, normal
qnorm res12
scatter res12 week_ts
// white noise 
wntestq res12
drop if missing(week_ts)


*Dự báo tĩnh
arch price tb lượngmưa diệntíchgieotrồngha năngsuấtlúatạha sảnlượnglúatấnha sin52 cos52, arch(1/1) arima(2,1,2)
predict yhat, xb
* Dự đoán residuals
predict ehat, residuals
* Xem kết quả 10 quan sát cuối
list giágạohạtdài yhat ehat if _n > _N - 10
* Tạo giá trị dự báo "tuyệt đối" (phục hồi về chuỗi gốc từ sai phân)
gen giá_gạo_dự_báo = .
replace giá_gạo_dự_báo = L.giágạohạtdài + yhat if _n > 1
list giágạohạtdài giá_gạo_dự_báo if _n > _N - 10
* Vẽ đồ thị chuỗi thực tế và dự báo
tsline giágạohạtdài giá_gạo_dự_báo price

*Tính RMSE, MAPE và MAE
gen error = price - giá_gạo_dự_báo
gen abs_error = abs(error)
gen sq_error = error^2
drop if missing()
//MAE
summarize abs_error
//RMSE
summarize sq_error
display sqrt(r(mean))
//MAPE
gen ape = abs((price - giá_gạo_dự_báo) / price)
summarize ape
display r(mean)*100
