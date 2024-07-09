let solutions =[]; //gene length: 30, buildingType: 0-6, month in period, 11 times, price change, 4 apts, 2 raise, 8
let numberOfBuildingType = buildingTypes.length;

class Sheet {
    constructor() {
      this.buildingTypes = [];
      for (let i = 0; i < buildingTypes.length; i++) {
        this.buildingTypes.push(new Array(periodProlong).fill(0));
      }
  
      this.apartmentData = aptTypes.map((aptType) => ({
        stock: new Array(periodProlong).fill(0),
        salesCap: new Array(periodProlong).fill(aptType.lowPace),
        sales: new Array(periodProlong).fill(0),
        price: new Array(periodProlong).fill(aptType.lowPrice),
      }));
  
      this.revenues = new Array(periodProlong).fill(0);
      this.expenses = new Array(periodProlong).fill(0);
      this.cashFlows = new Array(periodProlong).fill(0);
      this.accumulatedCashFlow = new Array(periodProlong).fill(0);
      this.totalSales = new Array(periodProlong).fill(0);
      this.accumulatedSale = new Array(periodProlong).fill(0);
    }
  }