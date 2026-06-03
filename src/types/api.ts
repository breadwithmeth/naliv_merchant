export type Nullable<T> = T | null | undefined;

export type ApiEnvelope<T> = {
  success?: boolean;
  data?: T;
  message?: string;
  error?: {
    message?: string;
    statusCode?: number;
  };
  statusCode?: number;
};

export type User = {
  user_id?: number;
  id?: number;
  name?: string | null;
  login?: string | null;
};

export type Coordinates = {
  lat?: number | string | null;
  lon?: number | string | null;
  lng?: number | string | null;
  latitude?: number | string | null;
  longitude?: number | string | null;
};

export type AddressDetails = {
  apartment?: string | null;
  entrance?: string | null;
  floor?: string | null;
  comment?: string | null;
};

export type DeliveryAddress = {
  address_id?: number;
  name?: string | null;
  address?: string | null;
  coordinates?: Coordinates | null;
  details?: AddressDetails | null;
};

export type PaymentType = {
  payment_type_id?: number;
  id?: number;
  name?: string | null;
};

export type OrderStatus = {
  status?: number | null;
  status_name?: string | null;
  timestamp?: string | null;
  isCanceled?: number | boolean | null;
};

export type OrderCourier = {
  courier_id?: number;
  id?: number;
  login?: string | null;
  name?: string | null;
  access_level?: string | null;
};

export type OrderSummary = {
  order_id?: number;
  order_uuid?: string;
  user?: User | null;
  delivery_address?: DeliveryAddress | null;
  delivery_type?: string | null;
  delivery_price?: number | string | null;
  delivery_service_fee?: number | string | null;
  cost?: number | string | null;
  service_fee?: number | string | null;
  total_cost?: number | string | null;
  total_sum?: number | string | null;
  payment_type?: PaymentType | null;
  current_status?: OrderStatus | null;
  items_count?: number | string | null;
  delivery_date?: string | null;
  log_timestamp?: string | null;
  bonus?: number | string | null;
  extra?: string | null;
};

export type StatusHistory = OrderStatus & {
  status_id?: number;
};

export type ItemOption = {
  option_id?: number;
  option_name?: string | null;
  item_id?: number;
  name?: string | null;
  price?: number | string | null;
  selected_price?: number | string | null;
  amount?: number | string | null;
};

export type OrderItem = {
  relation_id?: number;
  item_id?: number;
  name?: string | null;
  description?: string | null;
  img?: string | null;
  barcode?: string | null;
  amount?: number | string | null;
  price?: number | string | null;
  unit?: string | null;
  original_price?: number | string | null;
  total_cost?: number | string | null;
  options?: ItemOption[] | null;
};

export type CostSummary = {
  items_total?: number | string | null;
  delivery_price?: number | string | null;
  delivery_service_fee?: number | string | null;
  service_fee?: number | string | null;
  bonus_used?: number | string | null;
  subtotal?: number | string | null;
  total_sum?: number | string | null;
};

export type Business = {
  business_id?: number;
  id?: number;
  name?: string | null;
  address?: string | null;
  coordinates?: Coordinates | null;
};

export type OrderDetail = OrderSummary & {
  courier?: OrderCourier | null;
  status_history?: StatusHistory[] | null;
  items?: OrderItem[] | null;
  cost_summary?: CostSummary | null;
  created_at?: string | null;
};

export type OrdersData = {
  orders?: OrderSummary[];
  pagination?: Pagination;
};

export type Pagination = {
  page?: number;
  limit?: number;
  total?: number;
  totalPages?: number;
  hasNext?: boolean;
  hasPrev?: boolean;
};

export type OrderDetailsData = {
  order?: OrderDetail;
  business?: Business;
};

export type CourierLocationPoint = {
  courier_id?: number;
  id?: number;
  name?: string | null;
  login?: string | null;
  latitude?: number | string | null;
  longitude?: number | string | null;
  lat?: number | string | null;
  lon?: number | string | null;
  lng?: number | string | null;
  updated_at?: string | null;
  location?: {
    lat?: number | string | null;
    lon?: number | string | null;
    lng?: number | string | null;
    updated_at?: string | null;
  } | null;
  courier?: OrderCourier | null;
};

export type CourierLocationsData =
  | CourierLocationPoint[]
  | {
      couriers?: CourierLocationPoint[];
      locations?: CourierLocationPoint[];
      items?: CourierLocationPoint[];
      data?: CourierLocationPoint[];
    };

export type CourierReportData = {
  summary?: {
    total_delivered_orders?: number | string | null;
    orders_with_courier?: number | string | null;
    orders_without_courier?: number | string | null;
    total_delivery_revenue?: number | string | null;
    [key: string]: unknown;
  };
  orders?: CourierReportOrder[];
  [key: string]: unknown;
};

export type CourierReportOrder = {
  order_id?: number | string | null;
  courier?: OrderCourier | null;
  delivery_price?: number | string | null;
  delivery_service_fee?: number | string | null;
  total_sum?: number | string | null;
  order_created?: string | null;
  delivery_address?: string | DeliveryAddress | null;
  payment_type?: PaymentType | null;
  current_status?: OrderStatus | null;
};

export type CourierShift = {
  shift_id?: string | number | null;
  id?: string | number | null;
  courier_id?: number | string | null;
  courier?: OrderCourier | null;
  started_at?: string | null;
  ended_at?: string | null;
  status?: string | null;
  orders_count?: number | string | null;
  total_amount?: number | string | null;
  totals?: {
    orders_count?: number | string | null;
    total_amount?: number | string | null;
    [key: string]: unknown;
  };
  payment_types?: PaymentTypeSummary[];
  orders?: CourierReportOrder[];
  [key: string]: unknown;
};

export type PaymentTypeSummary = {
  name?: string | null;
  orders?: number | string | null;
  deliveryRevenue?: number | string | null;
  delivery_revenue?: number | string | null;
  deliveryServiceFee?: number | string | null;
  delivery_service_fee?: number | string | null;
  totalOrderSum?: number | string | null;
  total_order_sum?: number | string | null;
  orderSumWithoutDelivery?: number | string | null;
  order_sum_without_delivery?: number | string | null;
  total_amount?: number | string | null;
  amount?: number | string | null;
};
